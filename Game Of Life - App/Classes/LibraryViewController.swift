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
    @IBOutlet private         var treeController: NSTreeController?
    @IBOutlet private         var outlineView:    NSOutlineView?
    @objc     private dynamic var library:        [ LibraryItem ]?
    
    override var nibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.reload()
    }
    
    public func reload()
    {
        self.library = LibraryItem.allItems()
        
        self.treeController?.sortDescriptors = [ NSSortDescriptor( key: "title", ascending: true ) ]
        
        self.outlineView?.expandItem( nil, expandChildren: true )
    }
    
    func outlineView( _ outlineView: NSOutlineView, shouldCollapseItem item: Any ) -> Bool
    {
        return false
    }
    
    func outlineView( _ outlineView: NSOutlineView, shouldSelectItem item: Any ) -> Bool
    {
        return false
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
        if( i.count == 0 )
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
    
    override func controlTextDidChange( _ notification: Notification )
    {
        guard let searchField = notification.object as? NSSearchField else
        {
            return
        }
        
        var predicate: NSPredicate?
        
        if( searchField.stringValue != "" )
        {
            predicate = NSPredicate( format: "title contains[cd] %@", argumentArray: [ searchField.stringValue ] )
        }
            
        for item in self.library ?? []
        {
            item.setPredicate( predicate )
        }
        
        self.outlineView?.expandItem( nil, expandChildren: true )
    }
}
