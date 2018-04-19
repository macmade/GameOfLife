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

class LibraryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource
{
    @IBOutlet private         var arrayController: NSArrayController?
    @IBOutlet private         var tableView:       NSTableView?
    @objc     private dynamic var library:         [ LibraryItem ]?
    
    override var nibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.library = LibraryItem.allItems()
    }
    
    func itemAt( _ row: Int ) -> LibraryItem?
    {
        if( row >= self.library?.count ?? 0 )
        {
            return nil
        }
        
        return self.library?[ row ]
    }
    
    func tableView( _ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        guard let item = self.itemAt( row ) else
        {
            return 0
        }
        
        if( item.kind == .Group )
        {
            return 24
        }
        
        return 38
    }
    
    func tableView( _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int ) -> NSView?
    {
        guard let item = self.itemAt( row ) else
        {
            return nil
        }
        
        if( item.kind == .Group )
        {
            return tableView.makeView( withIdentifier: NSUserInterfaceItemIdentifier( "GroupCell" ), owner: self )
        }
        
        return tableView.makeView( withIdentifier: NSUserInterfaceItemIdentifier( "ItemCell" ), owner: self )
    }
    
    func tableView( _ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard ) -> Bool
    {
        if( rowIndexes.count != 1 )
        {
            return false
        }
        
        guard let index = rowIndexes.first else
        {
            return false
        }
        
        guard let item = self.itemAt( index ) else
        {
            return false
        }
        
        if( item.kind != .Item )
        {
            return false
        }
        
        return pboard.writeObjects( [ item ] )
    }
}
