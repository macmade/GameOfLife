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
    
    @objc public dynamic var title:       String
    @objc public dynamic var subtitle:    String
    @objc public dynamic var author:      String
    @objc public dynamic var rule:        String
    @objc public dynamic var comment:     String
    @objc public dynamic var tooltip:     String
    @objc public dynamic var isGroup:     Bool
    @objc public dynamic var width:       Int
    @objc public dynamic var height:      Int
    @objc public dynamic var allChildren: [ LibraryItem ]
    @objc public dynamic var children:    [ LibraryItem ]
    
    @objc public private( set ) dynamic var cells:     [ String ]
    @objc public private( set ) dynamic var rotations: [ [ String ] ]
    
    init( title: String = "", cells: [ String ] = [] )
    {
        self.title       = title
        self.subtitle    = ""
        self.author      = ""
        self.rule        = ""
        self.comment     = ""
        self.tooltip     = ""
        self.isGroup     = cells.count == 0
        self.cells       = cells
        self.rotations   = []
        self.allChildren = []
        self.children    = []
        
        var n = 0
        
        for s in cells
        {
            n = max( n, s.count )
        }
        
        self.width  = n
        self.height = cells.count
        
        super.init()
    }
    
    public func setSubtitle()
    {
        var sub = ""
        
        if( self.width > 0 && self.height > 0 )
        {
            sub += String( describing: self.width )
            sub += "x"
            sub += String( describing: self.height )
        }
        
        if( self.rule.count > 0 )
        {
            if( sub.count > 0 )
            {
                sub += ", "
            }
            
            sub += self.rule
        }
        
        self.subtitle = sub
    }
    
    public func setTooltip()
    {
        if( self.author.count > 0 && self.comment.count > 0 )
        {
            self.tooltip = self.comment + "\n(" + self.author + ")"
        }
        else if( self.author.count > 0 )
        {
            self.tooltip = self.author
        }
        else if( self.comment.count > 0 )
        {
            self.tooltip = self.comment
        }
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
        self.cells = self.rotate( cells: self.cells )
    }
    
    public func rotate( cells: [ String ] ) -> [ String ]
    {
        var n = 0
        
        for s in cells
        {
            n = max( n, s.count )
        }
        
        var r = [ String ]()
        
        for _ in 0 ..< n
        {
            r.append( "" )
        }
        
        for i in 0 ..< cells.count
        {
            for j in 0 ..< n
            {
                if( j < cells[ i ].count )
                {
                    let c = cells[ i ][ String.Index( encodedOffset: j ) ]
                    
                    r[ j ].append( c )
                }
                else
                {
                    r[ j ].append( " " )
                }
            }
        }
        
        var ret = [ String ]()
        
        for i in 0 ..< r.count
        {
            ret.append( String( r[ i ].reversed() ) )
        }
        
        return ret
    }
    
    public func prepareRotations( done: @escaping () -> Void )
    {
        if( self.rotations.count > 0 )
        {
            return
        }
        
        DispatchQueue.global( qos: .default ).async
        {
            var rotations = [ [ String ] ]()
            var cells     = self.cells
            
            for _ in 0 ... 2
            {
                cells = self.rotate( cells: cells )
                
                rotations.append( cells )
            }
            
            self.rotations = rotations
            
            DispatchQueue.main.sync
            {
                done()
            }
        }
    }
    
    // MARK: - NSCopying
    
    func copy( with zone: NSZone? = nil ) -> Any
    {
        let item = LibraryItem()
        
        item.title       = self.title
        item.subtitle    = self.subtitle
        item.author      = self.author
        item.rule        = self.rule
        item.comment     = self.comment
        item.tooltip     = self.tooltip
        item.isGroup     = self.isGroup
        item.width       = self.width
        item.height      = self.height
        item.cells       = self.cells
        item.rotations   = self.rotations
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
        self.subtitle    = item.subtitle
        self.author      = item.author
        self.rule        = item.rule
        self.comment     = item.comment
        self.tooltip     = item.tooltip
        self.isGroup     = item.isGroup
        self.width       = item.width
        self.height      = item.height
        self.cells       = item.cells
        self.rotations   = item.rotations
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
        
        guard let subtitle = coder.decodeObject( forKey: "subtitle" ) as? String else
        {
            return nil
        }
        
        guard let author = coder.decodeObject( forKey: "author" ) as? String else
        {
            return nil
        }
        
        guard let rule = coder.decodeObject( forKey: "rule" ) as? String else
        {
            return nil
        }
        
        guard let comment = coder.decodeObject( forKey: "comment" ) as? String else
        {
            return nil
        }
        
        guard let tooltip = coder.decodeObject( forKey: "tooltip" ) as? String else
        {
            return nil
        }
        
        guard let cells = coder.decodeObject( of: NSArray.self, forKey: "cells" ) as? [ String ] else
        {
            return nil
        }
        
        guard let rotations = coder.decodeObject( of: NSArray.self, forKey: "rotations" ) as? [ [ String ] ] else
        {
            return nil
        }
        
        guard let children = coder.decodeObject( of: NSArray.self, forKey: "children" ) as? [ LibraryItem ] else
        {
            return nil
        }
        
        self.title       = title
        self.subtitle    = subtitle
        self.author      = author
        self.rule        = rule;
        self.comment     = comment
        self.tooltip     = tooltip
        self.isGroup     = coder.decodeBool( forKey: "isGroup" )
        self.width       = coder.decodeInteger( forKey: "width" )
        self.height      = coder.decodeInteger( forKey: "height" )
        self.cells       = cells
        self.rotations   = rotations
        self.allChildren = children
        self.children    = children
    }
    
    func encode( with coder: NSCoder )
    {
        coder.encode( self.title,      forKey: "title" )
        coder.encode( self.subtitle,   forKey: "subtitle" )
        coder.encode( self.author ,    forKey: "author" )
        coder.encode( self.rule,       forKey: "rule" )
        coder.encode( self.comment,    forKey: "comment" )
        coder.encode( self.tooltip,    forKey: "tooltip" )
        coder.encode( self.isGroup,    forKey: "isGroup" )
        coder.encode( self.width,      forKey: "width" )
        coder.encode( self.height,     forKey: "height" )
        coder.encode( self.cells,      forKey: "cells" )
        coder.encode( self.rotations,  forKey: "rotations" )
        coder.encode( self.children,   forKey: "children" )
    }
}
