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

class LibraryViewerWindowController: NSWindowController
{
    @IBOutlet private var libraryViewContainer: NSView?
    @IBOutlet private var infosController:      NSArrayController?
    @IBOutlet private var textView:             NSTextView?
    @IBOutlet private var detailView:           LibraryItemDetailView?
    
    @objc dynamic public private( set ) var libraryViewController: LibraryViewController?
    @objc dynamic public private( set ) var selectedItem:          LibraryItem?
    @objc dynamic public private( set ) var infos:                 [ StringPair ]?
    @objc dynamic public private( set ) var comments:              NSAttributedString?
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        self.window?.appearance = NSAppearance( named: .vibrantDark )
        
        self.libraryViewController            = LibraryViewController()
        self.libraryViewController?.allowDrag = true
        
        guard let container = self.libraryViewContainer else
        {
            return
        }
        
        guard let view = self.libraryViewController?.view else
        {
            return
        }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview( view )
        container.addConstraint( NSLayoutConstraint( item: view, attribute: .width,   relatedBy: .equal, toItem: container, attribute: .width,   multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: view, attribute: .height,  relatedBy: .equal, toItem: container, attribute: .height,  multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: view, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: view, attribute: .centerY, relatedBy: .equal, toItem: container, attribute: .centerY, multiplier: 1, constant: 0 ) )
        
        self.libraryViewController?.onSelect = { ( item ) in self.select( item: item ) }
        
        self.infosController?.sortDescriptors = [ NSSortDescriptor( key: "key", ascending: true ) ]
        
        self.textView?.font               = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        self.textView?.textColor          = NSColor.disabledControlTextColor
        self.textView?.linkTextAttributes = [ NSAttributedStringKey.foregroundColor: NSColor( hex: 0x5EA09F ) ]
    }
    
    private func select( item: LibraryItem? )
    {
        guard let i = item else
        {
            self.selectedItem = item
            
            return
        }
        
        var infos = [ StringPair ]()
        
        infos.append( StringPair( key: "Author:", value: i.author ) )
        infos.append( StringPair( key: "Rule:",   value: i.rule ) )
        
        if( i.width > 0 && i.height > 0 )
        {
            infos.append( StringPair( key: "Width:",  value: String( describing: i.width ) ) )
            infos.append( StringPair( key: "Height:", value: String( describing: i.height ) ) )
        }
        
        let attr = [ NSAttributedStringKey.foregroundColor: NSColor.disabledControlTextColor ]
        
        self.comments     = NSAttributedString( string: i.comment, attributes: attr )
        self.infos        = infos
        self.selectedItem = item
        
        self.detailView?.updateItem( item )
        
        self.textView?.isEditable = true
        
        self.textView?.checkTextInDocument( nil )
        
        self.textView?.isEditable = false
    }
}

