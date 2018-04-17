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

class LibraryItemView: NSView
{
    private var item: LibraryItem?
    
    private var width:  Int = 0
    private var height: Int = 0
    
    override func draw( _ rect: NSRect )
    {
        self.getItem()
        
        guard let cells = self.item?.cells else
        {
            return
        }
        
        let n1 = max( self.width, self.height )
        let n2 = min( self.bounds.width, self.bounds.height )
        let d  = CGFloat( n2 ) / CGFloat( n1 )
        
        for y in 0 ..< cells.count
        {
            let s = cells[ y ]
            
            for x in 0 ..< s.count
            {
                let c = s[ String.Index( encodedOffset: x ) ]
                
                if( c == " " )
                {
                    continue
                }
                
                let rect = NSRect( x: CGFloat( x ) * d, y: CGFloat( y ) * d, width: d, height: d )
                
                NSColor.black.setFill()
                rect.fill()
            }
        }
    }
    
    private func getItem()
    {
        if( self.item != nil || self.superview == nil )
        {
            return
        }
        
        guard let item = self.findItem( view: self.superview ) else
        {
            return
        }
        
        var width = 0
        
        for s in item.cells
        {
            width = max( s.count, width )
        }
        
        self.width  = width
        self.height = item.cells.count
        self.item   = item
    }
    
    private func findItem( view: NSView? ) -> LibraryItem?
    {
        guard let cell = view as? NSTableCellView else
        {
            return self.findItem( view: view?.superview ) 
        }
        
        guard let item = cell.objectValue as? LibraryItem else
        {
            return self.findItem( view: view?.superview ) 
        }
        
        
        
        return item
    }
}
