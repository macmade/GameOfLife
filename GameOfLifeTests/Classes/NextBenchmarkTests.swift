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

/// A coarse performance baseline for `Grid.next()`.
///
/// Swift Testing has no built-in `measure`, so this times a fixed workload with
/// `DispatchTime` and prints the result (recorded in the milestone notes). The
/// assertion is a generous upper bound — a regression guard, not a tight metric.
/// Build configuration matters: this runs in Debug (`-Onone`); the figure is a
/// relative baseline for comparing against the chunked-grid rewrite under the
/// same configuration.
@Suite( "next() performance baseline" )
@MainActor
struct NextBenchmarkTests
{
    /// Times `next()` over a representative grid and prints the per-generation cost.
    ///
    /// The active rule is deliberately left untouched: `next()` scans the whole
    /// grid and counts eight neighbours per cell regardless of the rule, so its
    /// cost is rule-independent. Avoiding the shared `Preferences.rule` here also
    /// keeps this long-running test from racing the serialized evolution suite.
    @Test( "next() baseline on a 256x256 grid" )
    func nextBaseline()
    {
        let side        = 256
        let generations = 50
        let grid        = Grid( width: side, height: side, kind: .Random )

        let start = DispatchTime.now()

        ( 0 ..< generations ).forEach { _ in grid.next() }

        let end      = DispatchTime.now()
        let seconds  = Double( end.uptimeNanoseconds - start.uptimeNanoseconds ) / 1_000_000_000
        let perGenMs = ( seconds / Double( generations ) ) * 1000

        print( "next() baseline: \( generations ) generations on \( side )x\( side ) in \( seconds )s (\( perGenMs ) ms/gen)" )

        #expect( seconds < 60 )
    }
}
