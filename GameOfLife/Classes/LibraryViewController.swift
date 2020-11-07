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

class LibraryViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSSearchFieldDelegate
{
    typealias OnSelectHandler = ( _ item: LibraryItem? ) -> Void
    
    public var onSelect: OnSelectHandler?
    
    @IBOutlet public private( set ) var searchField:    NSSearchField?
    @IBOutlet private               var treeController: NSTreeController?
    @IBOutlet private               var outlineView:    NSOutlineView?
    @IBOutlet private               var progress:       ProgressIndicator?
    
    @objc private dynamic var library:    [ LibraryItem ]?
    @objc private dynamic var itemsText:  String?
    @objc private dynamic var itemsCount: Int = 0
    @objc private dynamic var loading:    Bool = false
    @objc public  dynamic var allowDrag:  Bool = false
    
    private var observations:  [ NSKeyValueObservation ] = []
    
    override var nibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func viewDidLoad()
    {
        let o1 = self.observe( \LibraryViewController.loading )
        {
            ( o, c ) in
            
            if( self.loading )
            {
                self.progress?.startAnimation( nil )
            }
            else
            {
                self.progress?.stopAnimation( nil )
            }
        }
        
        self.observations.append( contentsOf: [ o1 ] )
        
        super.viewDidLoad()
        self.reload()
        
        self.view.appearance = NSAppearance( named: .vibrantDark )
    }
    
    public func reload()
    {
        self.loading = true
        
        DispatchQueue.global( qos: .userInitiated).async
        {
            let bundled = Bundle.main.url( forResource: "Library", withExtension: "json" )
            let copy    = FileManager.default.urls( for: .applicationSupportDirectory, in: .userDomainMask ).first?.appendingPathComponent( "Library.json" )
            
            let url = ( copy != nil && FileManager.default.fileExists( atPath: copy!.path ) ) ? copy : bundled
            
            var library: [ LibraryItem ]
            
            if( url == nil )
            {
                library = []
            }
            else
            {
                let reader  = LibraryReader()
                library     = reader.read( url: url! ) ?? []
            }
            
            var n = 0
            
            for group in library
            {
                n += group.allChildren.count
            }
            
            DispatchQueue.main.sync
            {
                self.library = library
                
                self.treeController?.sortDescriptors = [ NSSortDescriptor( key: "title", ascending: true ) ]
                
                self.outlineView?.expandItem( nil, expandChildren: true )
                
                self.loading = false
                
                self.itemsCount = n
                self.itemsText  = String( describing: n ) + " items"
            }
        }
    }
    
    func outlineView( _ outlineView: NSOutlineView, shouldCollapseItem item: Any ) -> Bool
    {
        return false
    }
    
    func outlineView( _ outlineView: NSOutlineView, shouldSelectItem item: Any ) -> Bool
    {
        if( self.onSelect == nil )
        {
            return false
        }
        
        guard let node = item as? NSTreeNode else
        {
            return false
        }
        
        guard let item = node.representedObject as? LibraryItem else
        {
            return false
        }
        
        return item.isGroup == false
    }
    
    func outlineViewSelectionDidChange( _ notification: Notification )
    {
        guard let onSelect = self.onSelect else
        {
            return
        }
        
        guard let nodes = self.treeController?.selectedNodes else
        {
            onSelect( nil )
            
            return
        }
        
        guard let item = nodes.first?.representedObject as? LibraryItem else
        {
            onSelect( nil )
            
            return
        }
        
        onSelect( item )
    }
    
    func outlineView( _ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item i: Any ) -> NSView?
    {
        guard let node = i as? NSTreeNode else
        {
            return nil
        }
        
        guard let item = node.representedObject as? LibraryItem else
        {
            return nil
        }
        
        if( item.isGroup )
        {
            return outlineView.makeView( withIdentifier: NSUserInterfaceItemIdentifier( "HeaderCell" ), owner: self )
        }
        
        return outlineView.makeView( withIdentifier: NSUserInterfaceItemIdentifier( "DataCell" ), owner: self )
    }
    
    func outlineView( _ outlineView: NSOutlineView, writeItems i: [ Any ], to pasteboard: NSPasteboard ) -> Bool
    {
        if( i.count == 0 || self.allowDrag == false )
        {
            return false
        }
        
        var items = [ LibraryItem ]()
        
        for n in i
        {
            guard let node = n as? NSTreeNode else
            {
                return false
            }
            
            guard let item = node.representedObject as? LibraryItem else
            {
                return false
            }
            
            if( item.isGroup )
            {
                return false
            }
            
            items.append( item )
        }
        
        return pasteboard.writeObjects( items )
    }
    
    func controlTextDidChange( _ notification: Notification )
    {
        guard let searchField = notification.object as? NSSearchField else
        {
            return
        }
        
        var n = 0
        
        for item in self.library ?? []
        {
            var predicate: NSPredicate?
            
            if( searchField.stringValue != "" )
            {
                predicate = NSPredicate( format: "title contains[cd] %@ || %@ contains[cd] %@", argumentArray: [ searchField.stringValue, item.title, searchField.stringValue ] )
            }
            
            item.setPredicate( predicate )
            
            n += item.children.count
        }
        
        if( searchField.stringValue.count == 0 )
        {
            self.itemsText = String( describing: n ) + " items"
        }
        else
        {
            self.itemsText = String( describing: n ) + " of " + String( describing: self.itemsCount ) + " items"
        }
        
        self.outlineView?.expandItem( nil, expandChildren: true )
    }
}
