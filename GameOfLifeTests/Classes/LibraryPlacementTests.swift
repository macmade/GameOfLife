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

/// Tests for placing library patterns into a grid via `add(cells:left:top:)` and
/// `load(item:)`, including population accounting and out-of-bounds clamping.
///
/// `add`/`load(item:)` use `"o"`/non-space for live cells and do not depend on
/// the active rule, so the suite runs unserialized.
@Suite( "Library item placement" )
@MainActor
struct LibraryPlacementTests
{
    /// `add(cells:left:top:)` places each non-space cell at the given offset and
    /// counts newly-live cells into the population.
    @Test( "add(cells:left:top:) places cells and counts population" )
    func addPlacesCells()
    {
        let grid = Grid( width: 5, height: 5, kind: .Blank )

        grid.add( cells: [ "oo", "oo" ], left: 1, top: 1 )

        #expect( grid.population == 4 )
        #expect( grid.isAliveAt( x: 1, y: 1 ) )
        #expect( grid.isAliveAt( x: 2, y: 2 ) )
        #expect( grid.isAliveAt( x: 0, y: 0 ) == false )
    }

    /// Spaces are treated as dead cells and do not add to the population.
    @Test( "add(cells:left:top:) treats spaces as dead" )
    func addTreatsSpacesAsDead()
    {
        let grid = Grid( width: 5, height: 5, kind: .Blank )

        grid.add( cells: [ "o o", " o " ], left: 0, top: 0 )

        #expect( grid.population == 3 )
        #expect( grid.isAliveAt( x: 0, y: 0 ) )
        #expect( grid.isAliveAt( x: 1, y: 0 ) == false )
        #expect( grid.isAliveAt( x: 2, y: 0 ) )
        #expect( grid.isAliveAt( x: 1, y: 1 ) )
    }

    /// Cells placed outside the legacy `width`/`height` window are kept on the
    /// unbounded plane rather than clamped away.
    @Test( "add(cells:left:top:) places cells outside the window onto the plane" )
    func addPlacesOutsideWindow()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.add( cells: [ "oooo", "oooo" ], left: 2, top: 2 )

        // All eight cells are placed, even though only (2, 2) is inside the 3×3
        // window; the rest live beyond it on the unbounded plane.
        let expected = Set(
            ( 0 ..< 2 ).flatMap { dy in ( 0 ..< 4 ).map { dx in [ 2 + dx, 2 + dy ] } }
        )

        #expect( grid.population == 8 )
        #expect( GridTestSupport.liveWorldCoordinates( grid ) == expected )
    }

    /// Cells placed at negative offsets land at negative world coordinates.
    @Test( "add(cells:left:top:) places cells at negative coordinates" )
    func addPlacesNegativeCoordinates()
    {
        let grid = Grid( width: 3, height: 3, kind: .Blank )

        grid.add( cells: [ "oo", "oo" ], left: -5, top: -5 )

        let expected: Set< [ Int ] > = [ [ -5, -5 ], [ -4, -5 ], [ -5, -4 ], [ -4, -4 ] ]

        #expect( grid.population == 4 )
        #expect( GridTestSupport.liveWorldCoordinates( grid ) == expected )
    }

    /// `load(item:)` centers a smaller pattern in the grid and sets the population.
    @Test( "load(item:) centers the pattern and sets population" )
    func loadItemCenters()
    {
        let grid = Grid( width: 9, height: 9, kind: .Blank )
        let item = LibraryItem( title: "Block", cells: [ "oo", "oo" ] )

        #expect( grid.load( item: item ) )
        #expect( grid.width  == 9 )
        #expect( grid.height == 9 )
        #expect( grid.population == 4 )

        // A 2×2 pattern centered in 9×9: offset (9 - 2) / 2 == 3.
        #expect( grid.isAliveAt( x: 3, y: 3 ) )
        #expect( grid.isAliveAt( x: 4, y: 4 ) )
    }

    /// `load(item:)` of an empty item fails.
    @Test( "load(item:) rejects an empty item" )
    func loadItemRejectsEmpty()
    {
        let grid = Grid( width: 4, height: 4, kind: .Blank )
        let item = LibraryItem( title: "Empty", cells: [] )

        #expect( grid.load( item: item ) == false )
    }
}
