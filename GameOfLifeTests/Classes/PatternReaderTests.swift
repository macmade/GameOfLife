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

/// Tests for the pattern readers/writer (`RLEReader`, `RLEWriter`, `CellReader`).
///
/// The reader/writer internals are `private`, so these go through the public
/// `read(url:)` / `data(for:…)` APIs using temporary files.
@Suite( "Pattern readers & writer" )
@MainActor
struct PatternReaderTests
{
    /// Writes `content` to a temporary file with the given extension.
    private func writeTemp( _ content: String, ext: String ) throws -> URL
    {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent( UUID().uuidString + "." + ext )

        try content.write( to: url, atomically: true, encoding: .ascii )

        return url
    }

    /// Writes `grid` to RLE via `RLEWriter`, then reads it back via `RLEReader`.
    private func roundTrip( _ grid: Grid ) throws -> LibraryItem?
    {
        guard let data = RLEWriter().data( for: grid, name: "Test", comments: nil ) else
        {
            return nil
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent( UUID().uuidString + ".rle" )

        try data.write( to: url )

        defer { try? FileManager.default.removeItem( at: url ) }

        return RLEReader().read( url: url )
    }

    // MARK: - RLEReader

    /// A single-row pattern decodes to the expected live cells.
    @Test( "RLEReader decodes a single-row pattern" )
    func rleReadsSingleRow() throws
    {
        let url  = try self.writeTemp( "x = 3, y = 1, rule = B3/S23\n3o!\n", ext: "rle" )
        let item = try #require( RLEReader().read( url: url ) )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( item.cells.filter { $0.isEmpty == false } == [ "ooo" ] )
    }

    /// `decode` seeds its line list with an empty string, so every decoded
    /// pattern carries a leading empty row. Documented here as a known quirk.
    @Test( "RLEReader prepends a leading empty row (documented quirk)" )
    func rleLeadingEmptyRow() throws
    {
        let url  = try self.writeTemp( "x = 2, y = 2, rule = B3/S23\n2o$2o!\n", ext: "rle" )
        let item = try #require( RLEReader().read( url: url ) )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( item.cells == [ "", "oo", "oo" ] )
    }

    /// A file without the `.rle` extension is rejected.
    @Test( "RLEReader rejects a non-.rle file" )
    func rleRejectsWrongExtension() throws
    {
        let url = try self.writeTemp( "3o!", ext: "txt" )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( RLEReader().read( url: url ) == nil )
    }

    /// An empty file is rejected.
    @Test( "RLEReader returns nil for an empty file" )
    func rleEmptyFile() throws
    {
        let url = try self.writeTemp( "", ext: "rle" )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( RLEReader().read( url: url ) == nil )
    }

    /// Malformed/truncated input (overflowing run count, stray tokens) must not
    /// crash the decoder.
    @Test( "RLEReader does not crash on malformed input" )
    func rleMalformedDoesNotCrash() throws
    {
        let url = try self.writeTemp( "x = 1, y = 1\n99999999999999999999o5b$$!\n", ext: "rle" )

        defer { try? FileManager.default.removeItem( at: url ) }

        // Result is intentionally unchecked; the test asserts only that the call
        // returns without trapping.
        _ = RLEReader().read( url: url )
    }

    // MARK: - RLEWriter

    /// The writer emits run counts, the live token and the end-of-pattern token.
    @Test( "RLEWriter emits run counts and the end-of-pattern token" )
    func writerEmitsTokens() throws
    {
        let grid = GridTestSupport.makeGrid( [ "OOO" ] )
        let data = try #require( RLEWriter().data( for: grid, name: "Row", comments: nil ) )
        let text = try #require( String( data: data, encoding: .ascii ) )
        let body = try #require( text.split( separator: "\n" ).last.map( String.init ) )

        #expect( body == "3o!" )
    }

    /// The writer separates rows with the end-of-line token.
    @Test( "RLEWriter emits an end-of-line token between rows" )
    func writerEmitsEndOfLine() throws
    {
        let grid = GridTestSupport.makeGrid( [ "O", "O" ] )
        let data = try #require( RLEWriter().data( for: grid, name: "Col", comments: nil ) )
        let text = try #require( String( data: data, encoding: .ascii ) )

        #expect( text.contains( "$" ) )
    }

    // MARK: - Round-trip

    /// A single-row pattern round-trips with its live cells preserved.
    @Test( "RLE round-trip preserves a single-row pattern's live cells" )
    func singleRowRoundTrip() throws
    {
        let grid = GridTestSupport.makeGrid( [ "OOO" ] )
        let item = try #require( try self.roundTrip( grid ) )

        #expect( item.cells.filter { $0.isEmpty == false } == [ "ooo" ] )
    }

    /// A multi-row pattern round-trips with its live cells preserved. (The
    /// reader's leading empty row is ignored here; it is covered separately.)
    @Test( "RLE round-trip preserves a multi-row pattern's live cells" )
    func multiRowRoundTrip() throws
    {
        let grid = GridTestSupport.makeGrid(
            [
                "OO",
                "OO",
            ]
        )
        let item = try #require( try self.roundTrip( grid ) )

        #expect( item.cells.filter { $0.isEmpty == false } == [ "oo", "oo" ] )
    }

    // MARK: - CellReader

    /// A `.cells` pattern decodes with its name, author and cells.
    @Test( "CellReader decodes a .cells pattern" )
    func cellReadsPattern() throws
    {
        let url  = try self.writeTemp( "!Name: Block\n!Author: Tester\n.O\nO.\n", ext: "cells" )
        let item = try #require( CellReader().read( url: url ) )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( item.title  == "Block" )
        #expect( item.author == "Tester" )
        #expect( item.cells  == [ " o", "o " ] )
    }

    /// A file without the `.cells` extension is rejected.
    @Test( "CellReader rejects a non-.cells file" )
    func cellRejectsWrongExtension() throws
    {
        let url = try self.writeTemp( ".O\nO.", ext: "txt" )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( CellReader().read( url: url ) == nil )
    }

    /// An empty file is rejected.
    @Test( "CellReader returns nil for an empty file" )
    func cellEmptyFile() throws
    {
        let url = try self.writeTemp( "", ext: "cells" )

        defer { try? FileManager.default.removeItem( at: url ) }

        #expect( CellReader().read( url: url ) == nil )
    }
}
