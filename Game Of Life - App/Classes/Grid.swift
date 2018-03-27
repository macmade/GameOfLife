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

class Grid
{
    typealias Array  = Swift.ContiguousArray
    typealias Row    = Array< Cell >
    typealias Table  = Array< Row >
    
    public private( set ) var colors: Bool   = true
    public private( set ) var turns:  UInt64 = 0
    public private( set ) var width:  size_t
    public private( set ) var height: size_t
    public private( set ) var cells:  Table
    
    enum Kind
    {
        case Random
        case StillLife
        case Oscillators
        case Spaceships
        case GospersGuns
    }
    
    public var population: UInt64
    {
        get
        {
            var n: UInt64 = 0
            
            for row in self.cells
            {
                for cell in row
                {
                    n += ( cell.isAlive ) ? 1 : 0
                }
            }
            
            return n
        }
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
        
        switch( kind )
        {
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
            for i in 0 ..< height
            {
                self.cells[ i ].grow( width ) { Cell() }
            }
        }
        
        self.width  = width
        self.height = height
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
        
        for i in 0 ..< cells.count
        {
            for j in 0 ..< cells[ i ].count
            {
                let cell  = cells[ i ][ j ]
                let alive = cell.isAlive
                let count = self.numberOfAdjacentLivingCells( x: j, y: i )
                
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
            }
        }
        
        self.cells = cells
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
    
    public func adjacentCells( x: size_t, y: size_t ) -> [ Cell ]
    {
        var ret:   [ Cell  ] = []
        let cells: [ Cell? ] =
        [
            self.cellAt( x: x - 1, y: y - 1 ),
            self.cellAt( x: x,     y: y - 1 ),
            self.cellAt( x: x + 1, y: y - 1 ),
            self.cellAt( x: x - 1, y: y ),
            self.cellAt( x: x + 1, y: y ),
            self.cellAt( x: x - 1, y: y + 1 ),
            self.cellAt( x: x,     y: y + 1 ),
            self.cellAt( x: x + 1, y: y + 1 )
        ]
        
        for c in cells
        {
            guard let cell = c else
            {
                continue
            }
            
            ret.append( cell )
        }
        
        return ret
    }
    
    public func numberOfAdjacentLivingCells( x: size_t, y: size_t ) -> size_t
    {
        var n: size_t = 0
        
        for cell in self.adjacentCells( x: x, y: y )
        {
            n += ( cell.isAlive ) ? 1 : 0
        }
        
        return n
    }
    
    private func _setupRandomGrid()
    {
        for row in self.cells
        {
            for cell in row
            {
                cell.isAlive = arc4random() % 3 == 1
            }
        }
    }
    
    private func _setupStillLifeGrid()
    {}
    
    private func _setupOscillatorsGrid()
    {}
    
    private func _setupSpaceshipsGrid()
    {}
    
    private func _setupGospersGunsGrid()
    {
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
                }
            }
        }
    }
}

