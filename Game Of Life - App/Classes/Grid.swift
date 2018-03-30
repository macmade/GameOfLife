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
    typealias Array  = Swift.ContiguousArray
    typealias Row    = Array< Cell >
    typealias Table  = Array< Row >
    
    @objc dynamic public private( set ) var turns:      UInt64 = 0
    @objc dynamic public private( set ) var population: UInt64 = 0
    
    public private( set ) var colors: Bool   = true
    public private( set ) var width:  size_t
    public private( set ) var height: size_t
    public private( set ) var cells:  Table
    
    enum Kind
    {
        case Blank
        case Random
        case StillLife
        case Oscillators
        case Spaceships
        case GospersGuns
    }
    
    public init( width: size_t, height: size_t, kind: Kind = .Random )
    {
        self.width  = width
        self.height = height
        self.cells  = Table()
        
        self.cells.grow( height ) { Row() }
        
        for i in 0 ..< height
        {
            self.cells[ i ].grow( width ) { Cell() }
        }
        
        super.init()
        
        switch( kind )
        {
            case .Blank:       self._setupBlankGrid()
            case .Random:      self._setupRandomGrid()
            case .StillLife:   self._setupStillLifeGrid()
            case .Oscillators: self._setupOscillatorsGrid()
            case .Spaceships:  self._setupSpaceshipsGrid()
            case .GospersGuns: self._setupGospersGunsGrid()
        }
    }
    
    public func resize( width: size_t, height: size_t )
    {
        if( height > self.height )
        {
            self.cells.grow( height ) { Row() }
        }
        
        if( width > self.width )
        {
            for i in 0 ..< max( self.height, height )
            {
                self.cells[ i ].grow( width ) { Cell() }
            }
        }
        
        self.height = height
        self.width  = width
    }
    
    public func next()
    {
        var cells = Table()
        
        cells.reserveCapacity( self.cells.count )
        
        for i in 0 ..< self.cells.count
        {
            cells.append( Row() )
            cells[ i ].reserveCapacity( self.cells[ i ].count )
            
            for j in 0 ..< self.cells[ i ].count
            {
                cells[ i ].append( self.cells[ i ][ j ].copy() as! Cell )
            }
        }
        
        if( self.turns < UInt64.max )
        {
            self.turns += 1
        }
        
        var x: size_t = 0
        var y: size_t = 0
        var n: UInt64 = 0
        
        for row in cells
        {
            x = 0
            
            for cell in row
            {
                let alive: Bool   = cell.isAlive
                var count: size_t = 0
                
                var c1: Cell? = nil
                var c2: Cell? = nil
                var c3: Cell? = nil
                var c4: Cell? = nil
                var c5: Cell? = nil
                var c6: Cell? = nil
                var c7: Cell? = nil
                var c8: Cell? = nil
                
                if( y > 0 )
                {
                    c1 = ( x > 0 ) ? self.cells[ y - 1 ][ x - 1 ] : nil
                    c2 = self.cells[ y - 1 ][ x ]
                    c3 = ( x < self.cells[ y ].count - 1 ) ? self.cells[ y - 1 ][ x + 1 ] : nil
                }
                
                c4 = ( x > 0 ) ? self.cells[ y  ][ x - 1 ] : nil
                c5 = ( x < self.cells[ y ].count - 1 ) ? self.cells[ y ][ x + 1 ] : nil
                
                if( y < self.cells.count - 1 )
                {
                    c6 = ( x > 0 ) ? self.cells[ y + 1 ][ x - 1 ] : nil
                    c7 = self.cells[ y + 1 ][ x ]
                    c8 = ( x < self.cells[ y ].count - 1 ) ? self.cells[ y + 1 ][ x + 1 ] : nil
                }
                
                if( c1?.isAlive ?? false ) { count += 1 }
                if( c2?.isAlive ?? false ) { count += 1 }
                if( c3?.isAlive ?? false ) { count += 1 }
                if( c4?.isAlive ?? false ) { count += 1 }
                if( c5?.isAlive ?? false ) { count += 1 }
                if( c6?.isAlive ?? false ) { count += 1 }
                if( c7?.isAlive ?? false ) { count += 1 }
                if( c8?.isAlive ?? false ) { count += 1 }
                
                if( alive && count < 2 )
                {
                    cell.isAlive = false
                }
                else if( alive && count > 3 )
                {
                    cell.isAlive = false
                }
                else if( alive == false && count == 3 )
                {
                    cell.isAlive = true
                }
                
                if( alive && cell.isAlive && cell.age < UInt64.max )
                {
                    cell.age = cell.age + 1
                }
                
                n += ( cell.isAlive ) ? 1 : 0
                x += 1
            }
            
            y += 1
        }
        
        self.population = n
        self.cells      = cells
    }
    
    public func cellAt( x: size_t, y: size_t ) -> Cell?
    {
        if(  y < 0 || y >= self.cells.count )
        {
            return nil
        }
        
        if( x < 0 || x >= self.cells[ y ].count )
        {
            return nil
        }
        
        return self.cells[ y ][ x ];
    }
    
    private func _setupBlankGrid()
    {}
    
    private func _setupRandomGrid()
    {
        var n: UInt64 = 0
        
        for row in self.cells
        {
            for cell in row
            {
                cell.isAlive = arc4random() % 3 == 1
                n           += ( cell.isAlive ) ? 1 : 0
            }
        }
        
        self.population = n
    }
    
    private func _setupStillLifeGrid()
    {}
    
    private func _setupOscillatorsGrid()
    {}
    
    private func _setupSpaceshipsGrid()
    {}
    
    private func _setupGospersGunsGrid()
    {
        var n: UInt64                = 0
        let c: Array< Array< Int > > =
        [
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 ],
                [ 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
        ];
        
        if( self.cells.count < c.count )
        {
            return;
        }
        
        if( self.cells[ 0 ].count < c[ 0 ].count )
        {
            return;
        }
        
        for i in 0 ..< c.count
        {
            for j in stride( from: 0, to: self.cells[ i ].count, by: c[ i ].count )
            {
                if( j + c[ i ].count > self.cells[ i ].count )
                {
                    continue;
                }
                
                for k in 0 ..< c[ i ].count
                {
                    self.cells[ i ][ j + k ].isAlive = c[ i ][ k ] == 1;
                    n                               += ( self.cells[ i ][ j + k ].isAlive ) ? 1 : 0
                }
            }
        }
        
        self.population = n
    }
}

