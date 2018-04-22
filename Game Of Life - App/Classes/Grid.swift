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

class Grid: NSObject
{
    typealias Cell  = UInt8
    typealias Array = ContiguousArray< Cell >
    
    @objc dynamic public private( set ) var turns:      UInt64 = 0
    @objc dynamic public private( set ) var population: UInt64 = 0
    
    public private( set ) var colors: Bool = true
    public private( set ) var width:  size_t
    public private( set ) var height: size_t
    public private( set ) var cells:  ContiguousArray< Cell >
    
    enum Kind
    {
        case Blank
        case Random
    }
    
    public init( width: size_t, height: size_t, kind: Kind = .Random )
    {
        self.width  = width
        self.height = height
        self.cells  = ContiguousArray< Cell >()
        
        self.cells.grow( width * height ) { Cell() }
        
        super.init()
        
        switch( kind )
        {
            case .Blank:  self.setupBlankGrid()
            case .Random: self.setupRandomGrid()
        }
    }
    
    public func resize( width: size_t, height: size_t )
    {
        var cells = ContiguousArray< Cell >()
        
        cells.reserveCapacity( width * height )
        
        var n: UInt64 = 0
        
        for y in 0 ..< height
        {
            for x in 0 ..< width
            {
                guard let cell = self.cellAt( x: x, y: y ) else
                {
                    cells.append( Cell() )
                    
                    continue
                }
                
                n += ( cell & 1 == 1 ) ? 1 : 0
                
                cells.append( cell )
            }
        }
        
        self.population = n
        self.cells      = cells
        self.height     = height
        self.width      = width
    }
    
    public func next()
    {
        var cells = ContiguousArray< Cell >()
        
        cells.grow( self.cells.count ) { Cell() }
        
        if( self.turns == UInt64.max )
        {
            return
        }
        
        self.turns += 1
        
        let width  = self.width
        let height = self.height
        
        var n: UInt64 = 0
        
        for y in 0 ..< height
        {
            for x in 0 ..< width
            {
                let old           = self.cells[ x + ( y * width ) ]
                var new           = old
                let alive: Bool   = old & 1 == 1
                var count: UInt8  = 0
                
                if( y > 0 )
                {
                    if( x > 0 )
                    {
                        count += self.cells[ ( x - 1 ) + ( ( y - 1 ) * width ) ] & 1
                    }
                    
                    count += self.cells[ x + ( ( y - 1 ) * width ) ] & 1
                    
                    if( x < width - 1 )
                    {
                        count += self.cells[ ( x + 1 ) + ( ( y - 1 ) * width ) ] & 1
                    }
                }
                
                if( x > 0 )
                {
                    count += self.cells[ ( x - 1 ) + ( y * width ) ] & 1
                }
                
                if( x < width - 1 )
                {
                    count += self.cells[ ( x + 1 ) + ( y * width ) ] & 1
                }
                
                if( y < height - 1 )
                {
                    if( x > 0 )
                    {
                        count += self.cells[ ( x - 1 ) + ( ( y + 1 ) * width ) ] & 1
                    }
                    
                    count += self.cells[ x + ( ( y + 1 ) * width ) ] & 1
                    
                    if( x < width - 1 )
                    {
                        count += self.cells[ ( x + 1 ) + ( ( y + 1 ) * width ) ] & 1
                    }
                }
                
                if( alive )
                {
                    if( count < 2 )
                    {
                        new = 0
                    }
                    else if( alive && count > 3 )
                    {
                        new = 0
                    }
                }
                else if( count == 3 )
                {
                    new = 1 | ( 1 << 1 )
                }
                
                let age = old >> 1
                
                if( alive && new & 1 == 1 && age < ( Cell.max >> 1 ) )
                {
                    new &= 1
                    new |= ( age + 1 ) << 1
                }
                
                cells[ x + ( y * width ) ] = new
                
                n += ( new & 1 == 1 ) ? 1 : 0
            }
        }
        
        self.population = n
        self.cells      = cells
    }
    
    public func cellAt( x: size_t, y: size_t ) -> Cell?
    {
        if( x < self.width && y < self.height )
        {
            return self.cells[ x + ( y * self.width ) ];
        }
        
        return nil
    }
    
    public func isAliveAt( x: size_t, y: size_t ) -> Bool
    {
        if( x < self.width && y < self.height )
        {
            return self.cells[ x + ( y * self.width ) ] & 1 == 1
        }
        
        return false
    }
    
    public func setAliveAt( x: size_t, y: size_t, value: Bool )
    {
        if( x < self.width && y < self.height )
        {
            self.cells[ x + ( y * self.width ) ] = ( value ) ? 1 : 0
        }
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
    
    public func data() -> Data
    {
        var data = Data()
        
        data.append( contentsOf: [ 71, 79, 76, 49 ] )
        data.append( UInt64( 0 ) )
        data.append( UInt64( self.width ) )
        data.append( UInt64( self.height ) )
        data.append( UInt64( Preferences.shared.cellSize ) )
        
        for cell in self.cells
        {
            data.append( cell )
        }
        
        return data
    }
    
    public func load( data: Data ) -> Bool
    {
        if( data.count < 36 )
        {
            return false
        }
        
        if( data[ 0 ] != 71 && data[ 1 ] != 79 && data[ 2 ] != 76 && data[ 3 ] != 49 )
        {
            return false
        }
        
        let _       = data.readUInt64( at: 4 )
        let width   = data.readUInt64( at: 12 )
        let height  = data.readUInt64( at: 20 )
        let size    = data.readUInt64( at: 28 )
        
        if( width > 0 && height > 0 && data.count - 36 != width * height )
        {
            return false
        }
        
        if( size > 10 )
        {
            return false
        }
        
        var cells     = Array()
        var n: UInt64 = 0
        
        cells.reserveCapacity( Int( width * height ) )
        
        for i in 36 ..< data.count
        {
            n += ( data[ i ] & 1 == 1 ) ? 1 : 0
            
            cells.append( data[ i ] )
        }
        
        Preferences.shared.cellSize = CGFloat( size )
        
        self.population = n
        self.cells      = cells
        self.width      = size_t( width )
        self.height     = size_t( height )
        
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
        
        var cells = Array()
        
        cells.grow( width * height ) { Cell() }
        
        self.cells  = cells
        self.width  = size_t( width )
        self.height = size_t( height )
        
        self.add( item: item, left: xOffset, top: yOffset )
        
        return true
    }
    
    public func add( item: LibraryItem, left: Int, top: Int )
    {
        if( item.cells.count == 0 )
        {
            return
        }
        
        for y in 0 ..< item.cells.count
        {
            let s = item.cells[ y ]
            
            for x in 0 ..< s.count
            {
                let c = s[ String.Index( encodedOffset: x ) ]
                
                if( c == " " )
                {
                    continue
                }
                
                let i = ( x + left ) + ( ( y + top ) * self.width )
                
                if( i < self.cells.count )
                {
                    if( cells[ i ] == 0 )
                    {
                        self.population += 1
                    }
                    
                    cells[ i ] = 1
                }
            }
        }
    }
}

