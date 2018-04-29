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

class LibraryReader
{
    typealias LibraryType = [ String: [ Any ] ]
    
    public func read( url: URL ) -> [ LibraryItem ]?
    {
        let dispatch = DispatchGroup()
        
        guard let data = NSData( contentsOf: url ) else
        {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject( with: data as Data, options: [] ) else
        {
            return nil
        }
        
        guard let lib = json as? LibraryType else
        {
            return nil
        }
        
        var library = [ LibraryItem ]()
        
        for p in lib
        {
            let group = LibraryItem( title: p.key )
            
                for i in p.value
                {
                    dispatch.enter()
                    
                    DispatchQueue.global( qos: .userInitiated ).async
                    {
                        guard let items = self.load( object: i ) else
                        {
                            return
                        }
                        
                        group.allChildren.append( contentsOf: items )
                        group.children.append( contentsOf: items )
                        
                        dispatch.leave()
                    }
                }
                
                dispatch.wait()
                library.append( group )
        }
        
        return library
    }
    
    private func load( include: String ) -> [ LibraryItem ]?
    {
        let library = ( Bundle.main.resourcePath as NSString? )?.appendingPathComponent( "Library" )
        let path    = include.replacingOccurrences( of: "$(LIBRARY)", with: library ?? "" )
        
        guard let data = NSData( contentsOf: URL( fileURLWithPath: path ) ) else
        {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject( with: data as Data, options: [] ) else
        {
            return nil
        }
        
        guard let array = json as? [ Any ] else
        {
            return nil
        }
        
        var ret = [ LibraryItem ]()
        
        for i in array
        {
            guard let items = self.load( object: i ) else
            {
                continue
            }
            
            ret.append( contentsOf: items )
        }
        
        return ret
    }
    
    private func load( patterns: String ) -> [ LibraryItem ]?
    {
        let library    = ( Bundle.main.resourcePath as NSString? )?.appendingPathComponent( "Library" )
        let path       = patterns.replacingOccurrences( of: "$(LIBRARY)", with: library ?? "" )
        let cellReader = CellReader()
        let rleReader  = RLEReader()
        
        let cells = cellReader.read( directory: URL( fileURLWithPath: path ) )
        let rle   = rleReader.read( directory: URL( fileURLWithPath: path ) )
        
        var items = [ LibraryItem ]()
        
        if( cells == nil && rle == nil || ( cells?.count == 0 && rle?.count == 0 ) )
        {
            return nil
        }
        
        if( cells?.count ?? 0 > 0 )
        {
            items.append( contentsOf: cells! )
        }
        
        if( rle?.count ?? 0 > 0 )
        {
            items.append( contentsOf: rle! )
        }
        
        return items
    }
    
    private func load( object: Any ) -> [ LibraryItem ]?
    {
        guard let dic = object as? [ String: Any ] else
        {
            guard let inc = object as? String else
            {
                return nil
            }
            
            let prefix1 = "include:"
            let prefix2 = "patterns:"
            
            if( inc.hasPrefix( prefix1 ) )
            {
                return self.load( include: ( inc as NSString ).substring( from: prefix1.count ) )
            }
            else if( inc.hasPrefix( prefix2 ) )
            {
                return self.load( patterns: ( inc as NSString ).substring( from: prefix2.count ) )
            }
            
            return nil
        }
        
        guard let title = dic[ "title" ] as? String else
        {
            return nil
        }
        
        guard let cells = dic[ "cells" ] as? [ String ] else
        {
            return nil
        }
        
        let item = LibraryItem( title: title, cells: cells )
        
        item.author  = dic[ "author" ]  as? String ?? ""
        item.comment = dic[ "comment" ] as? String ?? ""
        item.tooltip = dic[ "tooltip" ] as? String ?? ""
        
        if( item.tooltip.count == 0 )
        {
            if( item.author.count > 0 && item.comment.count > 0 )
            {
                item.tooltip = item.comment + "\n(" + item.author + ")"
            }
            else if( item.author.count > 0 )
            {
                item.tooltip = item.author
            }
            else if( item.comment.count > 0 )
            {
                item.tooltip = item.comment
            }
        }
        
        return [ item ]
    }
}

