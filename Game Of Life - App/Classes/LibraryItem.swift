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
    
    typealias LibraryType = [ String: [ Any ] ]
    
    @objc public dynamic var title:       String
    @objc public dynamic var comment:     String
    @objc public dynamic var dimensions:  String
    @objc public dynamic var isGroup:     Bool
    @objc public dynamic var allChildren: [ LibraryItem ]
    @objc public dynamic var children:    [ LibraryItem ]
    @objc public dynamic var cells:       [ String ]
    
    init( title: String = "", cells: [ String ] = [] )
    {
        self.title       = title
        self.comment     = ""
        self.isGroup     = cells.count == 0
        self.cells       = cells
        self.allChildren = []
        self.children    = []
        
        var n = 0
        
        for s in cells
        {
            n = max( n, s.count )
        }
        
        self.dimensions = ( n == 0 ) ? "" : String( describing: n ) + "x" + String( describing: cells.count ) 
        
        super.init()
    }
    
    init?( cellFile: String )
    {
        if( cellFile.count == 0 )
        {
            return nil
        }
        
        let content    = cellFile.replacingOccurrences( of: "\r\n", with: "\n" ).replacingOccurrences( of: "\r", with: "\n" )
        var lines      = content.split( separator: "\n", omittingEmptySubsequences: false )
        let namePrefix = "!Name:"
        var cells      = [ String ]()
        
        var name:    String?
        var comment: String?
        
        while lines.last?.count == 0
        {
            lines.removeLast()
        }
        
        for line in lines
        {
            if( line.count == 0 )
            {
                if( cells.count > 0 )
                {
                    cells.append( " " )
                }
                
                continue
            }
            
            if( line.hasPrefix( namePrefix ) )
            {
                name = ( line as NSString ).substring( from: namePrefix.count ).trimmingCharacters( in: CharacterSet.whitespaces )
            }
            else if( line.hasPrefix( "!Author:" ) )
            {
                continue
            }
            else if( line.hasPrefix( "!" ) && comment == nil )
            {
                comment = ( line as NSString ).substring( from: 1 ).trimmingCharacters( in: CharacterSet.whitespaces )
            }
            
            let chars: Set< Character > = [ ".", "O" ]
            
            if( Set( line ).isSubset( of: chars ) == false )
            {
                continue
            }
            
            cells.append( line.replacingOccurrences( of: ".", with: " " ).replacingOccurrences( of: "O", with: "o" ) )
        }
        
        if( name == nil || name?.count == 0 )
        {
            return nil
        }
        
        if( cells.count == 0 )
        {
            return nil
        }
        
        self.title       = name!
        self.comment     = comment ?? ""
        self.isGroup     = cells.count == 0
        self.cells       = cells
        self.allChildren = []
        self.children    = []
        
        var n = 0
        
        for s in cells
        {
            n = max( n, s.count )
        }
        
        self.dimensions = ( n == 0 ) ? "" : String( describing: n ) + "x" + String( describing: cells.count ) 
        
        super.init()
    }
    
    public static func allItems() -> [ LibraryItem ]
    {
        let bundled = Bundle.main.url( forResource: "Library", withExtension: "json" )
        let copy    = FileManager.default.urls( for: .applicationSupportDirectory, in: .userDomainMask ).first?.appendingPathComponent( "Library.json" )
        
        guard let url = ( copy != nil && FileManager.default.fileExists( atPath: copy!.path ) ) ? copy : bundled else
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
    
    private static func load( include: String, in group: LibraryItem )
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
    
    private static func load( patterns: String, in group: LibraryItem )
    {
        let library = ( Bundle.main.resourcePath as NSString? )?.appendingPathComponent( "Library" )
        let path    = patterns.replacingOccurrences( of: "$(LIBRARY)", with: library ?? "" )
        var isDir   = ObjCBool( booleanLiteral: false )
        
        if( FileManager.default.fileExists( atPath: path, isDirectory: &isDir ) == false || isDir.boolValue == false )
        {
            return
        }
        
        do
        {
            for p in try FileManager.default.contentsOfDirectory( atPath: path )
            {
                let file = ( path as NSString ).appendingPathComponent( p )
                
                if( ( file as NSString ).pathExtension != "cells" && ( file as NSString ).pathExtension != "txt" )
                {
                    continue
                }
                
                do
                {
                    let data = try NSData( contentsOf: URL( fileURLWithPath: file ) ) as Data
                    
                    guard let content = String( data: data, encoding: .utf8 ) else
                    {
                        continue
                    }
                    
                    guard let item = LibraryItem( cellFile: content ) else
                    {
                        continue
                    }
                    
                    group.allChildren.append( item )
                    group.children.append( item )
                }
                catch
                {
                    continue
                }
                
            }
        }
        catch
        {}
    }
    
    public func dimensionsText() -> String
    {
        return ""
    }
    
    public func setPredicate( _ predicate: NSPredicate? )
    {
        if( predicate == nil )
        {
            self.children = self.allChildren
        }
        else
        {
            self.children = ( self.allChildren as NSArray ).filtered( using: predicate! ) as! [ LibraryItem ]
        }
    }
    
    public func rotate()
    {
        var n = 0
        
        for s in self.cells
        {
            n = max( n, s.count )
        }
        
        var r = [ String ]()
        
        for _ in 0 ..< n
        {
            r.append( "" )
        }
        
        for i in 0 ..< self.cells.count
        {
            for j in 0 ..< n
            {
                if( j < self.cells[ i ].count )
                {
                    let c = self.cells[ i ][ String.Index( encodedOffset: j ) ]
                    
                    r[ j ].append( c )
                }
                else
                {
                    r[ j ].append( " " )
                }
            }
        }
        
        self.cells.removeAll()
        
        for i in 0 ..< r.count
        {
            self.cells.append( String( r[ i ].reversed() ) )
        }
    }
    
    // MARK: - NSCopying
    
    func copy( with zone: NSZone? = nil ) -> Any
    {
        let item = LibraryItem()
        
        item.title       = self.title
        item.comment     = self.comment
        item.dimensions  = self.dimensions
        item.isGroup     = self.isGroup
        item.cells       = self.cells
        item.allChildren = self.allChildren
        item.children    = self.children
        
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
        
        self.title       = item.title
        self.comment     = item.comment
        self.dimensions  = item.dimensions
        self.isGroup     = item.isGroup
        self.cells       = item.cells
        self.allChildren = item.allChildren
        self.children    = item.children
    }
    
    // MARK: - NSSecureCoding
    
    static var supportsSecureCoding: Bool = true
    
    required init?( coder: NSCoder )
    {
        guard let title = coder.decodeObject( forKey: "title" ) as? String else
        {
            return nil
        }
        
        guard let comment = coder.decodeObject( forKey: "comment" ) as? String else
        {
            return nil
        }
        
        guard let dimensions = coder.decodeObject( forKey: "dimensions" ) as? String else
        {
            return nil
        }
        
        guard let cells = coder.decodeObject( of: NSArray.self, forKey: "cells" ) as? [ String ] else
        {
            return nil
        }
        
        guard let children = coder.decodeObject( of: NSArray.self, forKey: "children" ) as? [ LibraryItem ] else
        {
            return nil
        }
        
        self.title       = title;
        self.comment     = comment
        self.dimensions  = dimensions
        self.isGroup     = coder.decodeBool( forKey: "isGroup" );
        self.cells       = cells;
        self.allChildren = children;
        self.children    = children;
    }
    
    func encode( with coder: NSCoder )
    {
        coder.encode( self.title,      forKey: "title" )
        coder.encode( self.comment,    forKey: "comment" )
        coder.encode( self.dimensions, forKey: "dimensions" )
        coder.encode( self.isGroup,    forKey: "isGroup" )
        coder.encode( self.cells,      forKey: "cells" )
        coder.encode( self.children,   forKey: "children" )
    }
}
