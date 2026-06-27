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

import Cocoa
import Testing
@testable import GOL

/// Tests that custom-drawing views paint their whole `bounds` and do not rely on
/// the rect passed to their drawing method, which is only the dirty region and
/// is no longer guaranteed to equal `bounds`.
///
/// Each view is drawn with a tiny dirty rect in one corner; a far corner is then
/// checked to confirm it was still painted (it would be left blank if the view
/// drew only the passed rect).
///
/// `@MainActor` because these are `NSView`s.
@Suite( "Custom drawing fills bounds, not the dirty rect" )
@MainActor
struct DrawingBoundsTests
{
    private static let side = 40

    /// A tiny dirty rect in the bottom-left corner.
    private static let dirtyRect = NSRect( x: 0, y: 0, width: 4, height: 4 )

    /// Renders `draw` into a fresh transparent bitmap and returns the colour at
    /// the given pixel (far from ``dirtyRect``).
    private func farCorner( _ draw: () -> Void ) throws -> NSColor
    {
        let rep = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide:       Self.side,
                pixelsHigh:       Self.side,
                bitsPerSample:    8,
                samplesPerPixel:  4,
                hasAlpha:         true,
                isPlanar:         false,
                colorSpaceName:   .deviceRGB,
                bytesPerRow:      0,
                bitsPerPixel:     0
            )
        )
        let context = try #require( NSGraphicsContext( bitmapImageRep: rep ) )

        NSGraphicsContext.saveGraphicsState()

        NSGraphicsContext.current = context

        draw()

        NSGraphicsContext.restoreGraphicsState()

        return try #require( rep.colorAt( x: Self.side - 4, y: Self.side - 4 ) )
    }

    /// `ColorWell` fills its whole bounds even when only a corner is dirty.
    @Test( "ColorWell fills its whole bounds, not the dirty rect" )
    func colorWellFillsBounds() throws
    {
        let view = ColorWell( frame: NSRect( x: 0, y: 0, width: Self.side, height: Self.side ) )

        view.color = .red

        let corner = try self.farCorner { view.draw( Self.dirtyRect ) }

        #expect( corner.alphaComponent > 0.5 )
    }

    /// `RulerView` fills its whole background even when only a corner is dirty.
    @Test( "RulerView fills its whole background, not the dirty rect" )
    func rulerViewFillsBounds() throws
    {
        let view = RulerView()

        view.frame = NSRect( x: 0, y: 0, width: Self.side, height: Self.side )

        let corner = try self.farCorner { view.drawHashMarksAndLabels( in: Self.dirtyRect ) }

        #expect( corner.alphaComponent > 0.5 )
    }
}
