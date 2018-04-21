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
                guard let dic = i as? [ String: Any ] else
                {
                    guard let inc = i as? String else
                    {
                        continue
                    }
                    
                    let prefix1 = "include:"
                    let prefix2 = "patterns:"
                    
                    if( inc.hasPrefix( prefix1 ) )
                    {
                        self.load( include: ( inc as NSString ).substring( from: prefix1.count ), in: group )
                    }
                    else if( inc.hasPrefix( prefix2 ) )
                    {
                        self.load( patterns: ( inc as NSString ).substring( from: prefix2.count ), in: group )
                    }
                    
                    continue
                }
                
                guard let title = dic[ "title" ] as? String else
                {
                    continue
                }
                
                guard let cells = dic[ "cells" ] as? [ String ] else
                {
                    continue
                }
                
                let item = LibraryItem( title: title, cells: cells )
                
                item.comment = dic[ "comment" ] as? String ?? ""
                
                group.allChildren.append( item )
                group.children.append( item )
            }
            
            library.append( group )
        }
        
        return library
    }
    
    private func load( include: String, in group: LibraryItem )
    {
        let library = ( Bundle.main.resourcePath as NSString? )?.appendingPathComponent( "Library" )
        let path    = include.replacingOccurrences( of: "$(LIBRARY)", with: library ?? "" )
        
        guard let data = NSData( contentsOf: URL( fileURLWithPath: path ) ) else
        {
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject( with: data as Data, options: [] ) else
        {
            return
        }
        
        guard let items = json as? [ Any ] else
        {
            return
        }
        
        for i in items
        {
            guard let dic = i as? [ String: Any ] else
            {
                guard let inc = i as? String else
                {
                    continue
                }
                
                let prefix1 = "include:"
                let prefix2 = "patterns:"
                
                if( inc.hasPrefix( prefix1 ) )
                {
                    self.load( include: ( inc as NSString ).substring( from: prefix1.count ), in: group )
                }
                else if( inc.hasPrefix( prefix2 ) )
                {
                    self.load( patterns: ( inc as NSString ).substring( from: prefix2.count ), in: group )
                }
                
                continue
            }
            
            guard let title = dic[ "title" ] as? String else
            {
                continue
            }
            
            guard let cells = dic[ "cells" ] as? [ String ] else
            {
                continue
            }
            
            let item = LibraryItem( title: title, cells: cells )
            
            item.comment = dic[ "comment" ] as? String ?? ""
            
            group.allChildren.append( item )
            group.children.append( item )
        }
    }
    
    private func load( patterns: String, in group: LibraryItem )
    {
        let library = ( Bundle.main.resourcePath as NSString? )?.appendingPathComponent( "Library" )
        let path    = patterns.replacingOccurrences( of: "$(LIBRARY)", with: library ?? "" )
        let reader  = CellReader()
        
        guard let items = reader.read( directory: URL(fileURLWithPath: path ) ) else
        {
            return
        }
        
        for item in items
        {
            group.allChildren.append( item )
            group.children.append( item )
        }
    }
}

