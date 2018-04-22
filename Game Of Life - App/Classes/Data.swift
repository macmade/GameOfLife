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

extension Data
{
    public mutating func append( _ value: UInt16 )
    {
        self.append( UInt8( ( value >> 8 ) & 0xFF ) )
        self.append( UInt8( ( value      ) & 0xFF ) )
    }
    
    public mutating func append( _ value: UInt32 )
    {
        self.append( UInt16( ( value >> 16 ) & 0xFFFF ) )
        self.append( UInt16( ( value       ) & 0xFFFF ) )
    }
    
    public mutating func append( _ value: UInt64 )
    {
        self.append( UInt32( ( value >> 32 ) & 0xFFFFFFFF ) )
        self.append( UInt32( ( value       ) & 0xFFFFFFFF ) )
    }
    
    public func readUInt16( at: Int ) -> UInt16
    {
        return ( UInt16( self[ at ] ) << 8 ) | UInt16( self[ at + 1 ] )
    }
    
    public func readUInt32( at: Int ) -> UInt32
    {
        return UInt32( self.readUInt16( at: at ) ) << 16 | UInt32( self.readUInt16( at: at + 2 ) )
    }
    
    public func readUInt64( at: Int ) -> UInt64
    {
        return UInt64( self.readUInt32( at: at ) ) << 16 | UInt64( self.readUInt32( at: at + 4 ) )
    }
}
