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

import Testing
@testable import GOL

/// Tests for `Grid`'s unbounded cell accessors (`cellAt`/`isAliveAt`/
/// `setAliveAt`), which operate over the whole signed plane.
///
/// These tests do not run `next()`, so they do not depend on the active rule and
/// can run in parallel.
@Suite( "Grid accessors" )
@MainActor
struct GridAccessorTests
{
    /// Cells can be read and written anywhere on the plane — inside the initial
    /// extent, far beyond it, and at negative coordinates — and never-set cells
    /// read back dead.
    @Test( "accessors read and write at arbitrary world coordinates" )
    func accessorsAreUnbounded()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.setAliveAt( x: 1,    y: 1,   value: true )
        grid.setAliveAt( x: 1000, y: 500, value: true )
        grid.setAliveAt( x: -7,   y: -3,  value: true )

        #expect( grid.isAliveAt( x: 1,    y: 1 ) )
        #expect( grid.isAliveAt( x: 1000, y: 500 ) )
        #expect( grid.isAliveAt( x: -7,   y: -3 ) )
        #expect( grid.cellAt( x: 1, y: 1 ) == 1 )

        // A never-set cell reads back dead (zero), not as an out-of-bounds value.
        #expect( grid.isAliveAt( x: 2, y: 2 ) == false )
        #expect( grid.cellAt( x: 2, y: 2 ) == 0 )
    }

    /// `setAliveAt` toggles a cell on and off; clearing it sets the byte to zero.
    @Test( "setAliveAt sets and clears a cell" )
    func setAliveAtSetsAndClears()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.setAliveAt( x: 2, y: 2, value: true )

        #expect( grid.cellAt( x: 2, y: 2 ) == 1 )

        grid.setAliveAt( x: 2, y: 2, value: false )

        #expect( grid.cellAt( x: 2, y: 2 ) == 0 )
        #expect( grid.isAliveAt( x: 2, y: 2 ) == false )
    }

    /// `forEachLiveCell(inMinX:minY:maxX:maxY:)` yields only the live cells whose
    /// world coordinates fall inside the inclusive rectangle.
    @Test( "forEachLiveCell(in:) is restricted to the rectangle" )
    func liveCellsInRectangle()
    {
        let grid = Grid( width: 4, height: 4, kind: .Blank )

        grid.setAliveAt( x:  0, y: 0, value: true ) // inside
        grid.setAliveAt( x:  3, y: 3, value: true ) // inside (corner)
        grid.setAliveAt( x:  5, y: 5, value: true ) // outside (beyond max)
        grid.setAliveAt( x: -2, y: 1, value: true ) // outside (negative x)

        var found = Set< [ Int ] >()

        grid.forEachLiveCell( inMinX: 0, minY: 0, maxX: 3, maxY: 3 ) { x, y, _ in found.insert( [ x, y ] ) }

        #expect( found == [ [ 0, 0 ], [ 3, 3 ] ] )
    }
}
