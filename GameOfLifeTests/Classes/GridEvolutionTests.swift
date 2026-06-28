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

/// Tests for `Grid.next()` evolution under various rules, plus population/turn
/// bookkeeping and cell aging.
///
/// The suite is `.serialized` because every test drives the global active rule
/// through `Preferences.shared`, which `Grid` reads; running them concurrently
/// would let one test's rule leak into another's evolution.
@Suite( "Grid evolution", .serialized )
@MainActor
struct GridEvolutionTests
{
    // MARK: - Conway still lifes, oscillators, spaceships

    /// A 2×2 block is a still life: it is unchanged by a generation.
    @Test( "Conway: a block is a still life" )
    func blockIsStable()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let grid = GridTestSupport.makeGrid(
                [
                    "....",
                    ".OO.",
                    ".OO.",
                    "....",
                ]
            )

            let before = GridTestSupport.render( grid )

            grid.next()

            #expect( GridTestSupport.render( grid ) == before )
            #expect( grid.population == 4 )
        }
    }

    /// A blinker oscillates between horizontal and vertical with period 2.
    @Test( "Conway: a blinker oscillates with period 2" )
    func blinkerOscillates()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let horizontal = GridTestSupport.makeGrid(
                [
                    ".....",
                    ".....",
                    ".OOO.",
                    ".....",
                    ".....",
                ]
            )

            let expectedVertical = String(
                """
                .....
                ..O..
                ..O..
                ..O..
                .....
                """
            )

            let initial = GridTestSupport.render( horizontal )

            horizontal.next()

            #expect( GridTestSupport.render( horizontal ) == expectedVertical )
            #expect( horizontal.population == 3 )

            horizontal.next()

            #expect( GridTestSupport.render( horizontal ) == initial )
            #expect( horizontal.population == 3 )
        }
    }

    /// A glider returns to its original shape, translated by (+1, +1), after
    /// four generations.
    @Test( "Conway: a glider travels diagonally every four generations" )
    func gliderTravels()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            // Glider with its bounding box at origin (1, 1) on a 10×10 grid,
            // leaving room to move without touching an edge for four steps.
            let initialLive = [ [ 2, 1 ], [ 3, 2 ], [ 1, 3 ], [ 2, 3 ], [ 3, 3 ] ]
            let grid        = Grid( width: 10, height: 10, kind: .Blank )

            initialLive.forEach { grid.setAliveAt( x: $0[ 0 ], y: $0[ 1 ], value: true ) }

            ( 0 ..< 4 ).forEach { _ in grid.next() }

            let expectedLive = Set( initialLive.map { [ $0[ 0 ] + 1, $0[ 1 ] + 1 ] } )

            #expect( GridTestSupport.liveCoordinates( grid ) == expectedLive )
            #expect( grid.population == 5 )
        }
    }

    /// On the unbounded grid a glider keeps travelling indefinitely without ever
    /// hitting a boundary: after `4 * k` generations it is the original shape
    /// translated by `(+k, +k)`, well past the old fixed window, and its
    /// population is still 5.
    ///
    /// The window passed to `Grid(width:height:)` is only the legacy playfield
    /// extent; on the old dense model the glider would have collided with the
    /// edge of a 10×10 grid around generation 24 and disintegrated. This test
    /// runs 40 generations (a `(+10, +10)` shift) and queries the live cells
    /// through the unbounded `forEachLiveCell` seam rather than the windowed
    /// accessors, so it sees cells far outside the original window.
    @Test( "Conway: a glider travels far beyond the old fixed bounds" )
    func gliderTravelsUnbounded()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let initialLive = [ [ 2, 1 ], [ 3, 2 ], [ 1, 3 ], [ 2, 3 ], [ 3, 3 ] ]
            let steps       = 40
            let shift       = steps / 4
            let grid        = Grid( width: 10, height: 10, kind: .Blank )

            initialLive.forEach { grid.setAliveAt( x: $0[ 0 ], y: $0[ 1 ], value: true ) }

            ( 0 ..< steps ).forEach { _ in grid.next() }

            var live = Set< [ Int ] >()

            grid.forEachLiveCell { x, y, _ in live.insert( [ x, y ] ) }

            let expectedLive = Set( initialLive.map { [ $0[ 0 ] + shift, $0[ 1 ] + shift ] } )

            #expect( live == expectedLive )
            #expect( grid.population == 5 )
        }
    }

    // MARK: - Population & turn bookkeeping

    /// `turns` increments on each generation and `population` is recomputed.
    @Test( "turns increments and population is recomputed after evolution" )
    func turnsAndPopulationTracked()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let grid = GridTestSupport.makeGrid(
                [
                    ".....",
                    ".....",
                    ".OOO.",
                    ".....",
                    ".....",
                ]
            )

            #expect( grid.turns == 0 )

            grid.next()

            #expect( grid.turns      == 1 )
            #expect( grid.population == 3 )

            grid.next()

            #expect( grid.turns      == 2 )
            #expect( grid.population == 3 )
        }
    }

    /// `next()` is a no-op once `turns` reaches `UInt64.max`.
    ///
    /// `turns` has a private setter, so it is forced to the maximum via KVC
    /// (it is an `@objc dynamic` property). The test first asserts the KVC poke
    /// took effect, then that a further `next()` neither advances `turns` nor
    /// changes the cells.
    @Test( "next() is a no-op once turns saturates at UInt64.max" )
    func nextIsNoOpAtMaxTurns()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let grid = GridTestSupport.makeGrid(
                [
                    ".....",
                    ".OOO.",
                    ".....",
                ]
            )

            grid.setValue( NSNumber( value: UInt64.max ), forKey: "turns" )

            #expect( grid.turns == UInt64.max )

            let before = GridTestSupport.render( grid )

            grid.next()

            #expect( grid.turns == UInt64.max )
            #expect( GridTestSupport.render( grid ) == before )
        }
    }

    // MARK: - Alternate rules

    /// Seeds (B2/S): every live cell dies, and dead cells with exactly two live
    /// neighbours are born.
    @Test( "Seeds: live cells die, two-neighbour dead cells are born" )
    func seedsRule()
    {
        GridTestSupport.withActiveRule( "B2/S" )
        {
            let grid = GridTestSupport.makeGrid(
                [
                    ".....",
                    ".....",
                    ".OO..",
                    ".....",
                    ".....",
                ]
            )

            grid.next()

            let expected = String(
                """
                .....
                .OO..
                .....
                .OO..
                .....
                """
            )

            #expect( GridTestSupport.render( grid ) == expected )
            #expect( grid.population == 4 )
        }
    }

    /// HighLife (B36/S23): a dead cell with exactly six live neighbours is born,
    /// which is the only difference from Conway's Life and would stay dead there.
    @Test( "HighLife: a dead cell with six neighbours is born (unlike Conway)" )
    func highLifeBirthOnSix()
    {
        let sixNeighbours =
        [
            "OOO",
            "O.O",
            "O..",
        ]

        GridTestSupport.withActiveRule( "B36/S23" )
        {
            let grid = GridTestSupport.makeGrid( sixNeighbours )

            grid.next()

            #expect( grid.isAliveAt( x: 1, y: 1 ) )
        }

        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let grid = GridTestSupport.makeGrid( sixNeighbours )

            grid.next()

            #expect( grid.isAliveAt( x: 1, y: 1 ) == false )
        }
    }

    // MARK: - Cell aging

    /// A long-lived cell's age bits increment each generation and saturate at
    /// the cap (127) without ever clearing the alive bit.
    @Test( "Aging: a stable cell's age increments then saturates at 127" )
    func cellAgingSaturates()
    {
        GridTestSupport.withActiveRule( "B3/S23" )
        {
            let grid = GridTestSupport.makeGrid(
                [
                    "....",
                    ".OO.",
                    ".OO.",
                    "....",
                ]
            )

            // A cell set alive via setAliveAt starts at age 0 (raw byte 1).
            let initial = grid.cellAt( x: 1, y: 1 )

            #expect( initial == UInt8( 1 ) )

            // After k survivals the raw byte is `1 | (k << 1)` while age < 127.
            ( 0 ..< 5 ).forEach { _ in grid.next() }

            let afterFive = grid.cellAt( x: 1, y: 1 )

            #expect( afterFive == UInt8( 11 ) )
            #expect( grid.isAliveAt( x: 1, y: 1 ) )

            // Drive well past the cap; age saturates at 127, so the byte is
            // 1 | (127 << 1) == 255, and the cell is still alive.
            ( 0 ..< 200 ).forEach { _ in grid.next() }

            let saturated = grid.cellAt( x: 1, y: 1 )

            #expect( saturated == UInt8( 255 ) )
            #expect( grid.isAliveAt( x: 1, y: 1 ) )
        }
    }
}
