/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation
import Compression

/// The simulation core.
///
/// The world is an **unbounded** signed `(x, y)` plane. Live cells are stored
/// sparsely as fixed-size square tiles (see ``Tile``), allocated on demand and
/// reclaimed when they become empty, so memory tracks the live population rather
/// than the explored area.
///
/// `Grid` is the abstraction seam for the rest of the app: callers query and
/// mutate cells through its API rather than reaching into the storage. During
/// the migration it also keeps a *windowed facade* — `width`/`height`/`cells`,
/// `resize(width:height:)`, the bounds-checked `size_t` accessors and the v0
/// `.gol` round-trip — so the renderer (M8) and persistence (M7) keep working
/// unchanged against the legacy fixed playfield until their own milestones
/// retire the facade.
class Grid: NSObject
{
    typealias Cell  = UInt8

    /// On-demand storage for one square block of the plane: `tileSize × tileSize`
    /// cells in row-major order, each a ``Cell`` (bit 0 alive, bits 1–7 age).
    private typealias Tile = ContiguousArray< Cell >

    /// The tile coordinate of a populated block, i.e. world coordinates divided
    /// (floored) by ``tileSize``.
    private struct TileKey: Hashable
    {
        let col: Int
        let row: Int
    }

    /// Edge length of a square tile. A single tunable constant to revisit against
    /// the `next()` benchmark; 32 keeps each tile at 1 KiB.
    private static let tileSize = 32

    /// Number of cells in one tile (``tileSize`` squared).
    private static let cellsPerTile = Grid.tileSize * Grid.tileSize

    /*
     * Upper bound on the number of cells accepted from a loaded `.gol` file.
     * Cells are one byte each, so this caps a single load allocation at 256 MiB,
     * comfortably above any real grid (bounded by the screen size divided by the
     * minimum cell size), while preventing both arithmetic overflow and
     * gigabyte-scale allocations from a malformed or hostile file.
     */
    private static let maxCellCount: UInt64 = 1 << 28

    @objc dynamic public private( set ) var turns:      UInt64 = 0
    @objc dynamic public private( set ) var population: UInt64 = 0

    public private( set ) var colors: Bool = true
    public private( set ) var width:  size_t
    public private( set ) var height: size_t

    /// Populated tiles keyed by tile coordinate. A tile is present only while it
    /// holds at least one live cell; emptied tiles are removed.
    private var tiles: [ TileKey: Tile ] = [:]

    private var observations: [ NSKeyValueObservation ] = []

    private var rule = Preferences.shared.activeRule()

    enum Kind
    {
        case Blank
        case Random
    }

    public init( width: size_t, height: size_t, kind: Kind = .Random )
    {
        self.width  = width
        self.height = height

        super.init()

        switch( kind )
        {
            case .Blank:  self.setupBlankGrid()
            case .Random: self.setupRandomGrid()
        }

        let o1 = Preferences.shared.observe( \.rule )
        {
            ( o, c ) in self.rule = Preferences.shared.activeRule()
        }

        self.observations.append( contentsOf: [ o1 ] )
    }

    // MARK: - Tile / world-coordinate helpers

    /// The tile column or row owning a world coordinate, using *floored* division
    /// so negative coordinates map correctly (e.g. `-1` lives in tile `-1`).
    private static func tileIndex( _ coordinate: Int ) -> Int
    {
        let quotient  = coordinate / Grid.tileSize
        let remainder = coordinate % Grid.tileSize

        return ( remainder < 0 ) ? quotient - 1 : quotient
    }

    /// The in-tile offset (0..<``tileSize``) of a world coordinate, using
    /// *floored* modulo so it is always non-negative.
    private static func localIndex( _ coordinate: Int ) -> Int
    {
        let remainder = coordinate % Grid.tileSize

        return ( remainder < 0 ) ? remainder + Grid.tileSize : remainder
    }

    /// The raw cell byte at a world coordinate, or `0` (dead) when no tile is
    /// allocated there.
    private func cellValue( x: Int, y: Int ) -> Cell
    {
        let key = TileKey( col: Grid.tileIndex( x ), row: Grid.tileIndex( y ) )

        guard let tile = self.tiles[ key ] else
        {
            return 0
        }

        return tile[ Grid.localIndex( y ) * Grid.tileSize + Grid.localIndex( x ) ]
    }

    /// Writes a raw cell byte at a world coordinate, allocating the owning tile on
    /// demand and reclaiming it once it holds no live cells.
    private func setCellValue( x: Int, y: Int, value: Cell )
    {
        let key   = TileKey( col: Grid.tileIndex( x ), row: Grid.tileIndex( y ) )
        let index = Grid.localIndex( y ) * Grid.tileSize + Grid.localIndex( x )

        if( value == 0 )
        {
            guard var tile = self.tiles[ key ] else
            {
                return
            }

            tile[ index ]     = 0
            self.tiles[ key ] = tile.contains { $0 != 0 } ? tile : nil

            return
        }

        var tile = self.tiles[ key ] ?? Tile( repeating: 0, count: Grid.cellsPerTile )

        tile[ index ]     = value
        self.tiles[ key ] = tile
    }

    /// Calls `body` once for every live cell in the unbounded plane, passing its
    /// signed world coordinates and raw byte.
    ///
    /// This is the rendering/iteration seam over the tile store: unlike the
    /// windowed `size_t` accessors it sees the whole plane, including negative
    /// coordinates and cells far outside the legacy `width`/`height` window.
    ///
    /// - Parameter body: Receives `(x, y, cell)` for each live cell.
    public func forEachLiveCell( _ body: ( Int, Int, Cell ) -> Void )
    {
        let size = Grid.tileSize

        for ( key, tile ) in self.tiles
        {
            let baseX = key.col * size
            let baseY = key.row * size

            for ly in 0 ..< size
            {
                for lx in 0 ..< size
                {
                    let cell = tile[ ly * size + lx ]

                    if( cell & 1 == 1 )
                    {
                        body( baseX + lx, baseY + ly, cell )
                    }
                }
            }
        }
    }

    /// The bounding box of every live cell on the plane, or `nil` when the grid
    /// is empty. Used to export and frame the populated region independently of
    /// the legacy window.
    ///
    /// - Returns: The inclusive `(minX, minY, maxX, maxY)` extent of live cells.
    public func liveBounds() -> ( minX: Int, minY: Int, maxX: Int, maxY: Int )?
    {
        var bounds: ( minX: Int, minY: Int, maxX: Int, maxY: Int )?

        self.forEachLiveCell
        {
            x, y, _ in

            guard var current = bounds else
            {
                bounds = ( x, y, x, y )

                return
            }

            current.minX = min( current.minX, x )
            current.minY = min( current.minY, y )
            current.maxX = max( current.maxX, x )
            current.maxY = max( current.maxY, y )
            bounds       = current
        }

        return bounds
    }

    /// Reframes the legacy fixed playfield, keeping only the live cells inside the
    /// new `width`/`height` window and recomputing the population.
    ///
    /// This preserves the dense model's destructive resize semantics for the
    /// renderer; it is retired in M8 once the viewport replaces the fixed window.
    public func resize( width: size_t, height: size_t )
    {
        var kept: [ ( Int, Int, Cell ) ] = []

        self.forEachLiveCell
        {
            x, y, cell in

            if( x >= 0 && y >= 0 && x < width && y < height )
            {
                kept.append( ( x, y, cell ) )
            }
        }

        self.tiles  = [:]
        self.width  = width
        self.height = height

        kept.forEach { self.setCellValue( x: $0.0, y: $0.1, value: $0.2 ) }

        self.population = UInt64( kept.count )
    }

    /// Advances the simulation by one generation over the unbounded plane.
    ///
    /// Only the *active set* — every populated tile plus its eight neighbours, so
    /// births can appear in an empty tile adjacent to live cells — is processed.
    /// Each active tile's next state is computed from its own cells plus a 1-cell
    /// halo copied from the eight neighbouring tiles (zero where absent), keeping
    /// the inner loop local with no per-cell dictionary lookups. Aging,
    /// `population`, `turns` and the `turns == UInt64.max` no-op are preserved.
    public func next()
    {
        if( self.turns == UInt64.max )
        {
            return
        }

        self.turns += 1

        let size   = Grid.tileSize
        let stride = size + 2
        let bs     = self.rule.bornSet
        let ss     = self.rule.surviveSet

        var active = Set< TileKey >()

        for key in self.tiles.keys
        {
            for dr in -1 ... 1
            {
                for dc in -1 ... 1
                {
                    active.insert( TileKey( col: key.col + dc, row: key.row + dr ) )
                }
            }
        }

        var next: [ TileKey: Tile ] = [:]
        var n: UInt64               = 0

        for key in active
        {
            // Fetch the 3×3 block of neighbouring tiles once (centre at index 4).
            var neighbours = [ Tile? ]( repeating: nil, count: 9 )

            for dr in -1 ... 1
            {
                for dc in -1 ... 1
                {
                    neighbours[ ( dr + 1 ) * 3 + ( dc + 1 ) ] = self.tiles[ TileKey( col: key.col + dc, row: key.row + dr ) ]
                }
            }

            let center = neighbours[ 4 ]

            // Build the (size+2)² halo of alive bits: the centre tile plus a
            // 1-cell border drawn from the eight neighbours (zero where absent).
            var pad = ContiguousArray< UInt8 >( repeating: 0, count: stride * stride )

            for dr in -1 ... 1
            {
                for dc in -1 ... 1
                {
                    guard let tile = neighbours[ ( dr + 1 ) * 3 + ( dc + 1 ) ] else
                    {
                        continue
                    }

                    for ly in 0 ..< size
                    {
                        let gy = dr * size + ly

                        if( gy < -1 || gy > size )
                        {
                            continue
                        }

                        for lx in 0 ..< size
                        {
                            let gx = dc * size + lx

                            if( gx < -1 || gx > size )
                            {
                                continue
                            }

                            pad[ ( gy + 1 ) * stride + ( gx + 1 ) ] = tile[ ly * size + lx ] & 1
                        }
                    }
                }
            }

            var out     = Tile( repeating: 0, count: Grid.cellsPerTile )
            var hasLive = false

            for ly in 0 ..< size
            {
                let r0 = ly * stride
                let r1 = ( ly + 1 ) * stride
                let r2 = ( ly + 2 ) * stride

                for lx in 0 ..< size
                {
                    let count =   pad[ r0 + lx ] + pad[ r0 + lx + 1 ] + pad[ r0 + lx + 2 ]
                                + pad[ r1 + lx ]                       + pad[ r1 + lx + 2 ]
                                + pad[ r2 + lx ] + pad[ r2 + lx + 1 ] + pad[ r2 + lx + 2 ]

                    let old         = center?[ ly * size + lx ] ?? 0
                    var new         = old
                    let alive: Bool = old & 1 == 1

                    if( alive && ss.contains( Int( count ) ) == false )
                    {
                        new = 0
                    }
                    if( alive == false && bs.contains( Int( count ) ) )
                    {
                        new = 1 | ( 1 << 1 )
                    }

                    let age = old >> 1

                    if( alive && new & 1 == 1 && age < ( Cell.max >> 1 ) )
                    {
                        new &= 1
                        new |= ( age + 1 ) << 1
                    }

                    out[ ly * size + lx ] = new

                    if( new & 1 == 1 )
                    {
                        hasLive = true
                        n      += 1
                    }
                }
            }

            if( hasLive )
            {
                next[ key ] = out
            }
        }

        self.population = n
        self.tiles      = next
    }

    public func cellAt( x: size_t, y: size_t ) -> Cell?
    {
        if( x < self.width && y < self.height && x >= 0 && y >= 0 )
        {
            return self.cellValue( x: x, y: y )
        }

        return nil
    }

    public func isAliveAt( x: size_t, y: size_t ) -> Bool
    {
        if( x < self.width && y < self.height && x >= 0 && y >= 0 )
        {
            return self.cellValue( x: x, y: y ) & 1 == 1
        }

        return false
    }

    public func setAliveAt( x: size_t, y: size_t, value: Bool )
    {
        if( x < self.width && y < self.height && x >= 0 && y >= 0 )
        {
            self.setCellValue( x: x, y: y, value: ( value ) ? 1 : 0 )
        }
    }

    /// A dense snapshot of the legacy `[0, width) × [0, height)` window in
    /// row-major order — the windowed facade over the tile store, used by the v0
    /// `.gol` writer and available to call sites still expecting a flat array. It
    /// is materialized on access and removed in M8.
    public var cells: ContiguousArray< Cell >
    {
        var out = ContiguousArray< Cell >()

        out.reserveCapacity( self.width * self.height )

        for y in 0 ..< self.height
        {
            for x in 0 ..< self.width
            {
                out.append( self.cellValue( x: x, y: y ) )
            }
        }

        return out
    }

    private func setupBlankGrid()
    {}

    private func setupRandomGrid()
    {
        var n: UInt64 = 0

        for y in 0 ..< self.height
        {
            for x in 0 ..< self.width
            {
                let alive = arc4random() % 3 == 1

                self.setAliveAt( x: x, y: y, value: alive )

                n += ( alive ) ? 1 : 0
            }
        }

        self.population = n
    }

    /// Serializes the grid to the tiled v1 `.gol` format.
    ///
    /// Layout (big-endian, 76-byte header): magic `"GOL1"`, `UInt64` version (1),
    /// `cellSize`, `tileSize`, a scene block (`Int64` origin X/Y, `UInt64`
    /// view width/height — the viewport, reserved for M8 and filled with the
    /// current window for now), `tileCount`, and an LZFSE flag; then the payload,
    /// one record per populated tile: `Int64 col`, `Int64 row`, `tileSize²` cell
    /// bytes. Only populated tiles are written.
    public func data() -> Data
    {
        var data = Data()

        data.append( contentsOf: [ 71, 79, 76, 49 ] )        // "GOL1"
        data.append( UInt64( 1 ) )                           // format version
        data.append( UInt64( Preferences.shared.cellSize ) ) // cell size
        data.append( UInt64( Grid.tileSize ) )               // tile size
        data.append( UInt64( bitPattern: Int64( 0 ) ) )      // scene origin X (M8)
        data.append( UInt64( bitPattern: Int64( 0 ) ) )      // scene origin Y (M8)
        data.append( UInt64( self.width ) )                  // scene / view width
        data.append( UInt64( self.height ) )                 // scene / view height
        data.append( UInt64( self.tiles.count ) )            // tile count

        var payload = Data()

        self.tiles.forEach
        {
            key, tile in

            payload.append( UInt64( bitPattern: Int64( key.col ) ) )
            payload.append( UInt64( bitPattern: Int64( key.row ) ) )
            payload.append( contentsOf: tile )
        }

        guard let compressed = payload.compress( with: COMPRESSION_LZFSE ) else
        {
            data.append( UInt64( 0 ) ) // LZFSE flag
            data.append( payload )

            return data
        }

        data.append( UInt64( 1 ) ) // LZFSE flag
        data.append( compressed )

        return data
    }

    /// Loads a `.gol` file, dispatching on the version field: version 0 is the
    /// legacy fixed-size format (migrated into the plane at the world origin) and
    /// version 1 is the tiled format. Any other version is rejected.
    public func load( data: Data ) -> Bool
    {
        if( data.count < 12 )
        {
            return false
        }

        if( data[ 0 ] != 71 || data[ 1 ] != 79 || data[ 2 ] != 76 || data[ 3 ] != 49 )
        {
            return false
        }

        switch( data.readUInt64( at: 4 ) )
        {
            case 0:  return self.loadVersion0( data: data )
            case 1:  return self.loadVersion1( data: data )
            default: return false
        }
    }

    /// Reads the legacy fixed-size (v0) format, importing its live cells into the
    /// plane at the world origin. Kept so existing `.gol` files still open.
    private func loadVersion0( data: Data ) -> Bool
    {
        if( data.count < 44 )
        {
            return false
        }

        let width   = data.readUInt64( at: 12 )
        let height  = data.readUInt64( at: 20 )
        let size    = data.readUInt64( at: 28 )
        let lzfse   = data.readUInt64( at: 36 )

        if( size < 1 || size > 10 )
        {
            return false
        }

        let ( cellCount, overflow ) = width.multipliedReportingOverflow( by: height )

        if( overflow || cellCount > Grid.maxCellCount )
        {
            return false
        }

        let count = Int( cellCount )
        var bytes = ContiguousArray< Cell >()

        bytes.reserveCapacity( count )

        if( lzfse == 1 )
        {
            guard let decompressed = data.advanced( by: 44 ).decompress( with: COMPRESSION_LZFSE, bufferSize: count ) else
            {
                return false
            }

            if( decompressed.count != count )
            {
                return false
            }

            bytes.append( contentsOf: decompressed )
        }
        else
        {
            if( data.count - 44 != count )
            {
                return false
            }

            bytes.append( contentsOf: data.advanced( by: 44 ) )
        }

        self.tiles  = [:]
        self.width  = size_t( width )
        self.height = size_t( height )

        var n: UInt64 = 0

        for i in 0 ..< count
        {
            let cell = bytes[ i ]

            n += ( cell & 1 == 1 ) ? 1 : 0

            if( cell != 0 )
            {
                self.setCellValue( x: i % Int( width ), y: i / Int( width ), value: cell )
            }
        }

        Preferences.shared.cellSize = UInt( size )
        self.population             = n

        return true
    }

    /// Reads the tiled (v1) format. Cells are placed by world coordinate using the
    /// *file's* tile size, so the format survives a change to the build's tile
    /// size.
    private func loadVersion1( data: Data ) -> Bool
    {
        if( data.count < 76 )
        {
            return false
        }

        let size      = data.readUInt64( at: 12 )
        let tileSize  = data.readUInt64( at: 20 )
        let sceneW    = data.readUInt64( at: 44 )
        let sceneH    = data.readUInt64( at: 52 )
        let tileCount = data.readUInt64( at: 60 )
        let lzfse     = data.readUInt64( at: 68 )

        if( size < 1 || size > 10 )
        {
            return false
        }

        if( tileSize < 1 || tileSize > ( 1 << 16 ) )
        {
            return false
        }

        let ( cellsPerTile, overflow1 ) = tileSize.multipliedReportingOverflow( by: tileSize )

        if( overflow1 )
        {
            return false
        }

        let ( totalCells, overflow2 ) = tileCount.multipliedReportingOverflow( by: cellsPerTile )

        if( overflow2 || totalCells > Grid.maxCellCount )
        {
            return false
        }

        let recordSize                = Int( cellsPerTile ) + 16
        let ( payloadSize, overflow3 ) = Int( tileCount ).multipliedReportingOverflow( by: recordSize )

        if( overflow3 )
        {
            return false
        }

        let payload: Data

        if( lzfse == 1 )
        {
            guard let decompressed = data.advanced( by: 76 ).decompress( with: COMPRESSION_LZFSE, bufferSize: payloadSize ) else
            {
                return false
            }

            if( decompressed.count != payloadSize )
            {
                return false
            }

            payload = decompressed
        }
        else
        {
            if( data.count - 76 != payloadSize )
            {
                return false
            }

            payload = Data( Array( data.dropFirst( 76 ) ) )
        }

        self.tiles  = [:]
        self.width  = size_t( sceneW )
        self.height = size_t( sceneH )

        let edge      = Int( tileSize )
        var n: UInt64 = 0

        for t in 0 ..< Int( tileCount )
        {
            let base = t * recordSize
            let col  = Int( Int64( bitPattern: payload.readUInt64( at: base ) ) )
            let row  = Int( Int64( bitPattern: payload.readUInt64( at: base + 8 ) ) )

            for ly in 0 ..< edge
            {
                for lx in 0 ..< edge
                {
                    let cell = payload[ base + 16 + ly * edge + lx ]

                    if( cell == 0 )
                    {
                        continue
                    }

                    n += ( cell & 1 == 1 ) ? 1 : 0

                    self.setCellValue( x: col * edge + lx, y: row * edge + ly, value: cell )
                }
            }
        }

        Preferences.shared.cellSize = UInt( size )
        self.population             = n

        return true
    }

    public func load( item: LibraryItem ) -> Bool
    {
        if( item.cells.count == 0 )
        {
            return false
        }

        var width  = 0
        var height = item.cells.count

        for s in item.cells
        {
            width = max( width, s.count )
        }

        var xOffset = 0
        var yOffset = 0

        if( width < self.width )
        {
            xOffset = ( self.width - width ) / 2
            width   = self.width
        }

        if( height < self.height )
        {
            yOffset = ( self.height - height ) / 2
            height  = self.height
        }

        self.tiles  = [:]
        self.width  = size_t( width )
        self.height = size_t( height )

        self.add( item: item, left: xOffset, top: yOffset )

        return true
    }

    public func add( item: LibraryItem, left: Int, top: Int )
    {
        self.add( cells: item.cells, left: left, top: top )
    }

    public func add( cells: [ String ], left: Int, top: Int )
    {
        if( cells.count == 0 )
        {
            return
        }

        for y in 0 ..< cells.count
        {
            let s = cells[ y ]

            for x in 0 ..< s.count
            {
                let c = s[ String.Index( utf16Offset: x, in: s ) ]

                if( c == " " )
                {
                    continue
                }

                // The plane is unbounded: cells place at their world coordinate
                // with no width/height clamping, including negative coordinates.
                let wx = x + left
                let wy = y + top

                if( self.cellValue( x: wx, y: wy ) & 1 == 0 )
                {
                    self.population += 1
                }

                self.setCellValue( x: wx, y: wy, value: 1 )
            }
        }
    }
}
