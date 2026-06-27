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

/// Tests for the big-endian binary read/write helpers in `Data.swift`.
@Suite( "Data binary helpers" )
struct DataTests
{
    /// `UInt16` is appended most-significant byte first and read back identically.
    @Test( "UInt16 append/read is big-endian" )
    func uint16RoundTrips()
    {
        var data = Data()

        data.append( UInt16( 0x1234 ) )

        #expect( Array( data ) == [ 0x12, 0x34 ] )
        #expect( data.readUInt16( at: 0 ) == 0x1234 )
    }

    /// `UInt32` is appended big-endian and read back identically.
    @Test( "UInt32 append/read is big-endian" )
    func uint32RoundTrips()
    {
        var data = Data()

        data.append( UInt32( 0xDEADBEEF ) )

        #expect( Array( data ) == [ 0xDE, 0xAD, 0xBE, 0xEF ] )
        #expect( data.readUInt32( at: 0 ) == 0xDEADBEEF )
    }

    /// `UInt64` is appended big-endian, exercising both 32-bit words.
    @Test( "UInt64 append/read is big-endian across both words" )
    func uint64RoundTrips()
    {
        var data = Data()
        let value: UInt64 = 0x1122334455667788

        data.append( value )

        #expect( Array( data ) == [ 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88 ] )
        #expect( data.readUInt64( at: 0 ) == value )
    }

    /// `readUInt64` reconstructs the high and low 32-bit words independently,
    /// guarding the high-word shift.
    @Test( "readUInt64 reconstructs high and low words correctly" )
    func uint64HighAndLowWords()
    {
        var highOnly = Data()
        var lowOnly  = Data()

        highOnly.append( UInt64( 0xFFFFFFFF00000000 ) )
        lowOnly.append( UInt64( 0x00000000FFFFFFFF ) )

        #expect( highOnly.readUInt64( at: 0 ) == 0xFFFFFFFF00000000 )
        #expect( lowOnly.readUInt64( at: 0 ) == 0x00000000FFFFFFFF )
    }

    /// Reads honour the requested offset rather than assuming position zero.
    @Test( "reads honour a non-zero offset" )
    func readsHonourOffset()
    {
        var data = Data()

        data.append( UInt8( 0xAA ) )
        data.append( UInt32( 0xCAFEBABE ) )

        #expect( data.readUInt32( at: 1 ) == 0xCAFEBABE )
    }
}
