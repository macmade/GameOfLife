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
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 ******************************************************************************/

import Foundation
import Testing
@testable import GOL

/// Tests for `.gol` persistence: `Grid.data()` → `Grid.load(data:)` round-trips
/// and the malformed/oversized-header guards in `load(data:)`.
///
/// The suite is `.serialized` because `data()` reads, and `load(data:)` writes,
/// `Preferences.shared.cellSize`.
@Suite( "Grid .gol persistence", .serialized )
@MainActor
struct GridPersistenceTests
{
    /// Builds a `.gol` byte stream by hand (uncompressed branch) for guard tests.
    private func golData( width: UInt64, height: UInt64, size: UInt64, lzfse: UInt64, cells: [ UInt8 ] ) -> Data
    {
        var data = Data()

        data.append( contentsOf: [ 71, 79, 76, 49 ] ) // "GOL1"
        data.append( UInt64( 0 ) )                     // reserved
        data.append( width )
        data.append( height )
        data.append( size )
        data.append( lzfse )
        data.append( contentsOf: cells )

        return data
    }

    /// Builds a v1 (tiled) `.gol` byte stream by hand for the tiled read tests.
    private func golV1Data( cellSize: UInt64, tileSize: UInt64, sceneWidth: UInt64, sceneHeight: UInt64, lzfse: UInt64, tiles: [ ( col: Int64, row: Int64, bytes: [ UInt8 ] ) ] ) -> Data
    {
        var data = Data()

        data.append( contentsOf: [ 71, 79, 76, 49 ] ) // "GOL1"
        data.append( UInt64( 1 ) )                    // version
        data.append( cellSize )
        data.append( tileSize )
        data.append( UInt64( bitPattern: 0 ) )        // scene origin X
        data.append( UInt64( bitPattern: 0 ) )        // scene origin Y
        data.append( sceneWidth )
        data.append( sceneHeight )
        data.append( UInt64( tiles.count ) )          // tile count
        data.append( lzfse )

        tiles.forEach
        {
            data.append( UInt64( bitPattern: $0.col ) )
            data.append( UInt64( bitPattern: $0.row ) )
            data.append( contentsOf: $0.bytes )
        }

        return data
    }

    /// `load(data:)` reads a hand-built uncompressed v1 (tiled) stream, placing
    /// cells by world coordinate using the *file's* tile size — independent of the
    /// build's tile size — and at negative tile coordinates.
    @Test( "load() reads a hand-built uncompressed v1 (tiled) stream" )
    func tiledUncompressedLoad()
    {
        let previousSize = Preferences.shared.cellSize

        defer { Preferences.shared.cellSize = previousSize }

        // A 2×2 tile (deliberately not the build's tile size) at tile (-1, 3),
        // with its local cell (0, 1) alive.
        var tile           = [ UInt8 ]( repeating: 0, count: 4 )
        tile[ 1 * 2 + 0 ]  = 1

        let data = self.golV1Data( cellSize: 5, tileSize: 2, sceneWidth: 0, sceneHeight: 0, lzfse: 0, tiles: [ ( -1, 3, tile ) ] )
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) )

        // World coordinate = (col * tileSize + lx, row * tileSize + ly)
        //                  = (-1 * 2 + 0, 3 * 2 + 1) = (-2, 7).
        #expect( GridTestSupport.liveWorldCoordinates( grid ) == [ [ -2, 7 ] ] )
        #expect( grid.population == 1 )
        #expect( Preferences.shared.cellSize == 5 )
    }

    /// A v1 stream whose payload length does not match the declared tile count is
    /// rejected.
    @Test( "load() rejects a v1 stream with a truncated payload" )
    func tiledRejectsTruncatedPayload()
    {
        var tile  = [ UInt8 ]( repeating: 0, count: 4 )
        tile[ 0 ] = 1

        var data = self.golV1Data( cellSize: 5, tileSize: 2, sceneWidth: 0, sceneHeight: 0, lzfse: 0, tiles: [ ( 0, 0, tile ) ] )

        data.removeLast()

        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) == false )
    }

    /// A populated grid survives a `data()` → `load(data:)` round-trip through the
    /// compressed (LZFSE) branch, preserving dimensions, cells and population.
    @Test( "data() then load() round-trips through the compressed branch" )
    func compressedRoundTrip()
    {
        let previousSize = Preferences.shared.cellSize

        Preferences.shared.cellSize = 7

        defer { Preferences.shared.cellSize = previousSize }

        // A larger, mostly-blank grid so LZFSE actually compresses (tiny inputs
        // are left uncompressed). The lzfse flag at offset 36 must be 1.
        let grid = Grid( width: 24, height: 24, kind: .Blank )

        [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ], [ 10, 10 ], [ 23, 23 ] ].forEach
        {
            grid.setAliveAt( x: $0[ 0 ], y: $0[ 1 ], value: true )
        }

        let before = GridTestSupport.render( grid )
        let data   = grid.data()

        // In the v1 (tiled) format the LZFSE flag is at offset 68.
        #expect( data.readUInt64( at: 68 ) == 1 )

        let restored = Grid( width: 1, height: 1, kind: .Blank )

        #expect( restored.load( data: data ) )
        #expect( restored.width  == 24 )
        #expect( restored.height == 24 )
        #expect( restored.population == 5 )
        #expect( GridTestSupport.render( restored ) == before )
    }

    /// A grid with live cells outside the legacy window and at negative
    /// coordinates survives a `data()` → `load(data:)` round-trip through the new
    /// tiled (v1) format, which writes only populated tiles.
    @Test( "v1 round-trips cells outside the window and at negative coordinates" )
    func tiledRoundTripUnbounded()
    {
        let previousSize = Preferences.shared.cellSize

        Preferences.shared.cellSize = 6

        defer { Preferences.shared.cellSize = previousSize }

        let grid = Grid( width: 4, height: 4, kind: .Blank )

        grid.add( cells: [ "o" ],          left:   1, top:  1 ) // inside the window
        grid.add( cells: [ "ooo", "o o" ], left: 100, top: 80 ) // far outside it
        grid.add( cells: [ "oo", "oo" ],   left: -10, top: -7 ) // negative coords

        let before = GridTestSupport.liveWorldCoordinates( grid )
        let pop    = grid.population
        let data   = grid.data()

        // Version field at offset 4 is bumped to 1 for the tiled format.
        #expect( data.readUInt64( at: 4 ) == 1 )

        let restored = Grid( width: 1, height: 1, kind: .Blank )

        #expect( restored.load( data: data ) )
        #expect( GridTestSupport.liveWorldCoordinates( restored ) == before )
        #expect( restored.population == pop )
        #expect( Preferences.shared.cellSize == 6 )
    }

    /// `load(data:)` reads a hand-built uncompressed (`lzfse == 0`) stream.
    @Test( "load() reads the uncompressed branch" )
    func uncompressedLoad()
    {
        let previousSize = Preferences.shared.cellSize

        defer { Preferences.shared.cellSize = previousSize }

        let data = self.golData( width: 2, height: 2, size: 5, lzfse: 0, cells: [ 1, 0, 0, 1 ] )
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) )
        #expect( grid.width  == 2 )
        #expect( grid.height == 2 )
        #expect( grid.population == 2 )
        #expect( grid.isAliveAt( x: 0, y: 0 ) )
        #expect( grid.isAliveAt( x: 1, y: 1 ) )
        #expect( grid.isAliveAt( x: 1, y: 0 ) == false )
    }

    /// Too-short input is rejected.
    @Test( "load() rejects input shorter than the header" )
    func rejectsShortInput()
    {
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: Data( [ 1, 2, 3 ] ) ) == false )
    }

    /// A bad magic number is rejected.
    @Test( "load() rejects a bad magic number" )
    func rejectsBadMagic()
    {
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        // 44 zero bytes: valid length, but magic is not "GOL1".
        #expect( grid.load( data: Data( count: 48 ) ) == false )
    }

    /// An out-of-range cell size (must be 1...10) is rejected.
    @Test( "load() rejects an out-of-range cell size", arguments: [ UInt64( 0 ), UInt64( 11 ) ] )
    func rejectsBadCellSize( _ size: UInt64 )
    {
        let previousSize = Preferences.shared.cellSize

        defer { Preferences.shared.cellSize = previousSize }

        let data = self.golData( width: 2, height: 2, size: size, lzfse: 0, cells: [ 1, 0, 0, 1 ] )
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) == false )
    }

    /// Dimensions whose product overflows `UInt64` are rejected.
    @Test( "load() rejects dimensions that overflow" )
    func rejectsOverflowingDimensions()
    {
        let data = self.golData( width: UInt64.max, height: 2, size: 5, lzfse: 0, cells: [] )
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) == false )
    }

    /// A cell count beyond `maxCellCount` is rejected before allocation.
    @Test( "load() rejects a cell count above the maximum" )
    func rejectsOversizedCellCount()
    {
        // 2^20 * 2^20 == 2^40, far above the 2^28 cap, without overflowing.
        let data = self.golData( width: 1 << 20, height: 1 << 20, size: 5, lzfse: 0, cells: [] )
        let grid = Grid( width: 1, height: 1, kind: .Blank )

        #expect( grid.load( data: data ) == false )
    }
}
