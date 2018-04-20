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

class LibraryItem: NSObject, NSCopying, NSPasteboardWriting, NSPasteboardReading, NSSecureCoding
{
    public static let PasteboardType = NSPasteboard.PasteboardType( "com.xs-labs.GOL.LibraryItem" )
    
    typealias LibraryType = [ [ String: Any ] ]
    
    @objc public dynamic var title:    String
    @objc public dynamic var isGroup:  Bool
          public         var cells:    [ String ]
    
    init( title: String = "" )
    {
        self.title   = title
        self.isGroup = true
        self.cells   = [ String ]()
        
        super.init()
    }
    
    init( title: String = "", cells: [ String ] )
    {
        self.title   = title
        self.isGroup = false
        self.cells   = cells
        
        super.init()
    }
    
    public static func allItems() -> [ LibraryItem ]
    {
        guard let url = Bundle.main.url( forResource: "Library", withExtension: "json" ) else
        {
            return []
        }
        
        guard let data = NSData( contentsOf: url ) else
        {
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject( with: data as Data, options: [] ) else
        {
            return []
        }
        
        guard let lib = json as? LibraryType else
        {
            return []
        }
        
        var library = [ LibraryItem ]()
        
        for g in lib
        {
            guard let name = g[ "title" ] as? String else
            {
                continue
            }
            
            library.append( LibraryItem( title: name ) )
            
            guard let items = g[ "items" ] as? [ [ String: Any ] ] else
            {
                continue;
            }
            
            for i in items
            {
                guard let title = i[ "title" ] as? String else
                {
                    continue
                }
                
                guard let cells = i[ "cells" ] as? [ String ] else
                {
                    continue
                }
                
                library.append( LibraryItem( title: title, cells: cells ) )
            }
        }
        
        return library
    }
    
    // MARK: - NSCopying
    
    func copy( with zone: NSZone? = nil ) -> Any
    {
        let item = LibraryItem()
        
        item.title   = self.title
        item.isGroup = self.isGroup
        item.cells   = self.cells
        
        return item
    }
    
    // MARK: - NSPasteboardWriting
    
    func writableTypes( for pasteboard: NSPasteboard ) -> [ NSPasteboard.PasteboardType ]
    {
        return [ LibraryItem.PasteboardType ]
    }
    
    func pasteboardPropertyList( forType type: NSPasteboard.PasteboardType ) -> Any?
    {
        if( type != LibraryItem.PasteboardType )
        {
            return nil
        }
        
        return NSKeyedArchiver.archivedData( withRootObject: self )
    }
    
    // MARK: - NSPasteboardReading
    
    static func readingOptions( forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
    {
        if( type == LibraryItem.PasteboardType )
        {
            return .asKeyedArchive
        }
        
        return .asData
    }
    
    static func readableTypes( for pasteboard: NSPasteboard ) -> [ NSPasteboard.PasteboardType ]
    {
        return [ LibraryItem.PasteboardType ]
    }
    
    required init?( pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType )
    {
        if( type != LibraryItem.PasteboardType )
        {
            return nil
        }
        
        guard let data = propertyList as? Data else
        {
            return nil
        }
        
        guard let item = NSKeyedUnarchiver.unarchiveObject( with: data ) as? LibraryItem else
        {
            return nil
        }
        
        self.title   = item.title
        self.isGroup = item.isGroup
        self.cells   = item.cells
    }
    
    // MARK: - NSSecureCoding
    
    static var supportsSecureCoding: Bool = true
    
    required init?( coder: NSCoder )
    {
        guard let title = coder.decodeObject( forKey: "title" ) as? String else
        {
            return nil
        }
        
        guard let cells = coder.decodeObject( of: NSArray.self, forKey: "cells" ) as? [ String ] else
        {
            return nil
        }
        
        self.title   = title;
        self.isGroup = coder.decodeBool( forKey: "isGroup" );
        self.cells   = cells;
    }
    
    func encode( with coder: NSCoder )
    {
        coder.encode( self.title,   forKey: "title" )
        coder.encode( self.isGroup, forKey: "isGroup" )
        coder.encode( self.cells,   forKey: "cells" )
    }
}
