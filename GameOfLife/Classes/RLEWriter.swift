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

class RLEWriter
{
    public func data( for grid: Grid, name: String, comments: [ String ]? ) -> Data?
    {
        var lines = [ String ]()
        
        lines.append( "#N " + name )
        
        for c in comments ?? []
        {
            lines.append( "#C " + c )
        }
        
        let bundleName    = Bundle.main.object( forInfoDictionaryKey: "CFBundleName" )               as? String
        let shortVersion  = Bundle.main.object( forInfoDictionaryKey: "CFBundleShortVersionString" ) as? String
        let bundleVersion = Bundle.main.object( forInfoDictionaryKey: "CFBundleVersion" )            as? String
        
        let fmt       = DateFormatter()
        fmt.dateStyle = .long
        fmt.timeStyle = .medium
        
        var creator = fmt.string( from: Date() )
        
        if( bundleName != nil )
        {
            creator += ", " + bundleName!
        }
        
        if( shortVersion != nil && bundleVersion != nil )
        {
            creator += ", " + shortVersion! + " (" + bundleVersion! + ")"
        }
        else if( shortVersion != nil )
        {
            creator += ", " + shortVersion!
        }
        else if( bundleVersion != nil )
        {
            creator += ", " + bundleVersion!
        }
        
        lines.append( "#O " + creator )
        
        let coords = "x = "
                   + String( describing: grid.width )
                   + ", y = "
                   + String( describing: grid.height )
                   + ", rule = B3/S23"
        
        lines.append( coords )
        
        var old: Grid.Cell?
        var n   = 1
        var rle = ""
        
        for y in 0 ..< grid.height
        {
            for x in 0 ..< grid.width
            {
                let cell = grid.cells[ x + ( y * grid.width ) ]
                
                if( old != nil )
                {
                    if( cell & 1 == old! & 1 )
                    {
                        n += 1
                        
                        continue
                    }
                    
                    rle += ( ( n > 1 ) ? String( describing: n ) : "" ) + ( ( old! & 1 == 1 ) ? "o" : "b" )
                    n    = 1
                    
                    if( rle.count > 70 )
                    {
                        lines.append( rle )
                        
                        rle = ""
                    }
                }
                
                old = cell
            }
            
            rle += ( ( n > 1 ) ? String( describing: n ) : "" ) + ( ( old! & 1 == 1 ) ? "o" : "b" )
            n    = 1
            rle += ( y == grid.height - 1 ) ? "!" : "$"
            
            if( rle.count > 70 )
            {
                lines.append( rle )
                
                rle = ""
            }
        }
        
        lines.append( rle )
        
        return lines.joined( separator: "\n" ).data( using: .ascii )
    }
}
