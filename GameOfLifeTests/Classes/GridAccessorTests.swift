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

/// Tests for `Grid`'s cell accessors (`cellAt`/`isAliveAt`/`setAliveAt`) and for
/// `resize()` preserving in-bounds cells and recomputing the population.
///
/// These tests do not run `next()`, so they do not depend on the active rule and
/// can run in parallel.
@Suite( "Grid accessors & resize" )
@MainActor
struct GridAccessorTests
{
    /// In-bounds reads return a value; out-of-bounds reads return `nil`/`false`.
    @Test( "cellAt and isAliveAt are bounds-checked" )
    func accessorsAreBoundsChecked()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.setAliveAt( x: 1, y: 1, value: true )

        #expect( grid.cellAt( x: 1, y: 1 ) == 1 )
        #expect( grid.isAliveAt( x: 1, y: 1 ) )

        // Out of bounds in every direction.
        #expect( grid.cellAt( x: 3, y: 0 ) == nil )
        #expect( grid.cellAt( x: 0, y: 3 ) == nil )
        #expect( grid.cellAt( x: -1, y: 0 ) == nil )
        #expect( grid.cellAt( x: 0, y: -1 ) == nil )

        #expect( grid.isAliveAt( x: 3, y: 0 ) == false )
        #expect( grid.isAliveAt( x: -1, y: -1 ) == false )
    }

    /// `setAliveAt` toggles a cell and clears it; it never sets the age bits.
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

    /// `setAliveAt` out of bounds is a silent no-op (no crash, no change).
    @Test( "setAliveAt out of bounds does nothing" )
    func setAliveAtOutOfBoundsIsNoOp()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.setAliveAt( x: 5, y: 5, value: true )
        grid.setAliveAt( x: -1, y: 0, value: true )

        #expect( GridTestSupport.liveCoordinates( grid ).isEmpty )
    }

    /// Growing the grid preserves in-bounds cells and keeps the population.
    @Test( "resize to a larger grid preserves cells and population" )
    func resizeLargerPreservesCells()
    {
        let grid = Grid( width: 4, height: 4, kind: .Blank )

        grid.setAliveAt( x: 0, y: 0, value: true )
        grid.setAliveAt( x: 3, y: 3, value: true )

        grid.resize( width: 6, height: 6 )

        #expect( grid.width      == 6 )
        #expect( grid.height     == 6 )
        #expect( grid.population == 2 )
        #expect( grid.isAliveAt( x: 0, y: 0 ) )
        #expect( grid.isAliveAt( x: 3, y: 3 ) )
        #expect( grid.isAliveAt( x: 5, y: 5 ) == false )
    }

    /// Shrinking the grid drops out-of-bounds cells and recomputes the population.
    @Test( "resize to a smaller grid drops cells and recomputes population" )
    func resizeSmallerDropsCells()
    {
        let grid = Grid( width: 4, height: 4, kind: .Blank )

        grid.setAliveAt( x: 0, y: 0, value: true )
        grid.setAliveAt( x: 3, y: 3, value: true )

        grid.resize( width: 2, height: 2 )

        #expect( grid.width      == 2 )
        #expect( grid.height     == 2 )
        #expect( grid.population == 1 )
        #expect( grid.isAliveAt( x: 0, y: 0 ) )
        #expect( grid.cellAt( x: 3, y: 3 ) == nil )
    }
}
