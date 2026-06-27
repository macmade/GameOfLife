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
@testable import GOL

/// Shared helpers for the `Grid`/`Rule` tests: building grids from ASCII art,
/// rendering them back to ASCII for readable assertions, enumerating live cells,
/// and driving the global active rule that `Grid` reads from `Preferences`.
enum GridTestSupport
{
    /// The character used for a live cell in ASCII grid literals and renders.
    static let live = "O"

    /// The character used for a dead cell in ASCII grid literals and renders.
    static let dead = "."

    /// Runs `body` with `Preferences.shared.rule` set to `rule`, restoring the
    /// previous value afterwards.
    ///
    /// `Grid` takes its rule from `Preferences.shared.activeRule()`, so tests
    /// that exercise a specific rule must set it here. The shared preferences
    /// are global mutable state, so the suites using this helper are serialized.
    ///
    /// - Parameters:
    ///   - rule: The `B/S` rule string to make active (e.g. `"B3/S23"`).
    ///   - body: The work to perform while the rule is active.
    static func withActiveRule( _ rule: String, _ body: () throws -> Void ) rethrows
    {
        let previous = Preferences.shared.rule

        Preferences.shared.rule = rule

        defer { Preferences.shared.rule = previous }

        try body()
    }

    /// Builds a blank `Grid` from rows of ASCII art, turning on every cell whose
    /// character equals ``live`` (`"O"`). The grid width is the longest row.
    ///
    /// - Parameter rows: One string per grid row; `"O"` marks a live cell.
    /// - Returns: A blank grid with the marked cells set alive.
    static func makeGrid( _ rows: [ String ] ) -> Grid
    {
        let height = rows.count
        let width  = rows.map { $0.count }.max() ?? 0
        let grid   = Grid( width: width, height: height, kind: .Blank )

        rows.enumerated().forEach
        {
            y, row in row.enumerated().forEach
            {
                x, character in

                if String( character ) == live
                {
                    grid.setAliveAt( x: x, y: y, value: true )
                }
            }
        }

        return grid
    }

    /// Renders a grid back to ASCII art, one line per row, using ``live`` and
    /// ``dead`` for set and unset cells.
    ///
    /// - Parameter grid: The grid to render.
    /// - Returns: A newline-joined ASCII representation of the grid.
    static func render( _ grid: Grid ) -> String
    {
        ( 0 ..< grid.height ).map
        {
            y in String( ( 0 ..< grid.width ).map
            {
                x in Character( grid.isAliveAt( x: x, y: y ) ? live : dead )
            } )
        }
        .joined( separator: "\n" )
    }

    /// Returns the set of live cell coordinates as `[x, y]` pairs.
    ///
    /// - Parameter grid: The grid to inspect.
    /// - Returns: A set of `[x, y]` coordinates for every live cell.
    static func liveCoordinates( _ grid: Grid ) -> Set< [ Int ] >
    {
        let coordinates = ( 0 ..< grid.height ).flatMap
        {
            y in ( 0 ..< grid.width ).compactMap
            {
                x in grid.isAliveAt( x: x, y: y ) ? [ x, y ] : nil
            }
        }

        return Set( coordinates )
    }
}
