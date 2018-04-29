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

import Cocoa

class RLEReader
{
    public func read( directory: URL ) -> [ LibraryItem ]?
    {
        var isDir = ObjCBool( booleanLiteral: false )
        
        if( FileManager.default.fileExists( atPath: directory.path, isDirectory: &isDir ) == false || isDir.boolValue == false )
        {
            return nil
        }
        
        var items = [ LibraryItem ]()
        
        do
        {
            for p in try FileManager.default.contentsOfDirectory( atPath: directory.path )
            {
                let file = ( directory.path as NSString ).appendingPathComponent( p )
                
                guard let item = self.read( url: URL( fileURLWithPath: file ) ) else
                {
                    continue
                }
                
                items.append( item )
            }
        }
        catch
        {}
        
        return items
    }
    
    public func read( url: URL ) -> LibraryItem?
    {
        let file = url.path
        
        if( ( file as NSString ).pathExtension != "rle" )
        {
            return nil
        }
        
        do
        {
            let data = try NSData( contentsOf: URL( fileURLWithPath: file ) ) as Data
            
            guard let content = String( data: data, encoding: .ascii ) else
            {
                return nil
            }
            
            guard let item = self.read( content: content ) else
            {
                return nil
            }
            
            return item
        }
        catch
        {
            return nil
        }
    }
    
    private func read( content: String ) -> LibraryItem?
    {
        if( content.count == 0 )
        {
            return nil
        }
        
        let content = content.replacingOccurrences( of: "\r\n", with: "\n" ).replacingOccurrences( of: "\r", with: "\n" )
        var lines   = content.split( separator: "\n", omittingEmptySubsequences: false )
        
        var name:    String?
        var author:  String?
        var comment: String?
        var rule:    String?
        
        while lines.last?.count == 0
        {
            lines.removeLast()
        }
        
        var rle = ""
        
        for line in lines
        {
            if( line.count == 0 )
            {
                continue
            }
            
            if( line.hasPrefix( "#C" ) || line.hasPrefix( "#c" ) )
            {
                let c = ( line as NSString ).substring( from: 2 ).trimmingCharacters( in: CharacterSet.whitespaces )
                
                if( c.count > 0 )
                {
                    if( comment != nil )
                    {
                        comment?.append( "\n" + c )
                    }
                    else
                    {
                        comment = c
                    }
                }
            }
            else if( line.hasPrefix( "#N" ) )
            {
                name = ( line as NSString ).substring( from: 2 ).trimmingCharacters( in: CharacterSet.whitespaces )
            }
            else if( line.hasPrefix( "#O" ) )
            {
                author = ( line as NSString ).substring( from: 2 ).trimmingCharacters( in: CharacterSet.whitespaces )
            }
            else if( line.hasPrefix( "x" ) )
            {
                let infos = line.replacingOccurrences( of: " ", with: "" ).split( separator: "," )
                
                for info in infos
                {
                    if info.hasPrefix( "rule=" )
                    {
                        rule = ( info as NSString ).substring( from: 5 ).trimmingCharacters( in: CharacterSet.whitespaces )
                        
                        break
                    }
                }
            }
            else
            {
                let chars: Set< Character > = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "b", "o", "$", "!", " " ]
                
                if( Set( ( line as NSString ).substring( to: 1 ) ).isSubset( of: chars ) )
                {
                    rle += line
                }
            }
        }
        
        guard let cells = self.decode( rle: rle ) else
        {
            return nil
        }
        
        if( cells.count == 0 )
        {
            return nil
        }
        
        let item     = LibraryItem( title: name ?? "Untitled", cells: cells )
        item.author  = author            ?? ""
        item.rule    = rule?.capitalized ?? ""
        item.comment = comment           ?? ""
        
        item.setSubtitle()
        item.setTooltip()
        
        return item
    }
    
    private func decode( rle: String ) -> [ String ]?
    {
        let numeric: Set< Character > = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]
        
        var lines = [ "" ]
        var cur   = ""
        var n     = ""
        
        for c in rle
        {
            if( c == "!" )
            {
                lines.append( cur )
                
                break
            }
            else if( c == " " )
            {
                continue
            }
            else if( Set( String( c ) ).isSubset( of: numeric ) )
            {
                n += String( c )
                
                continue
            }
            else if( c == "$" )
            {
                lines.append( cur )
                
                let i = ( n == "" ) ? 1 : Int( n ) ?? 0
                
                for _ in 0 ..< i - 1
                {
                    lines.append( "" )
                }
                
                cur = ""
                n   = ""
                
                continue
            }
            else if( c == "b" || c == "o" )
            {
                let i = ( n == "" ) ? 1 : Int( n ) ?? 0
                var s = ""
                
                for _ in 0 ..< i
                {
                    s += String( ( c == "b" ) ? " " : "o" )
                }
                
                cur += s
                n    = ""
            }
        }
        
        return lines
    }
}
