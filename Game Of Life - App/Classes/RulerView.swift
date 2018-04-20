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

class RulerView: NSRulerView
{
    private var textView: NSTextView?
    
    override var clientView: NSView?
    {
        get
        {
            return super.clientView
        }
        
        set( view )
        {
            super.clientView = view
            
            guard let t = view as? NSTextView else
            {
                return
            }
            
            self.textView = t
        }
    }
    
    override func drawHashMarksAndLabels( in rect: NSRect )
    {
        self.textView?.textColor?.setFill()
        rect.fill()
        
        guard let t = self.textView else
        {
            return
        }
        
        let color = t.backgroundColor 
        
        guard let font = t.font else
        {
            return
        }
        
        guard let layoutManager = t.layoutManager else
        {
            return
        }
        
        guard let textContainer = layoutManager.textContainers.first else
        {
            return
        }
        
        guard let visibleRect = self.scrollView?.contentView.bounds else
        {
            return
        }
        
        guard let text = t.textStorage?.string as NSString? else
        {
            return
        }
        
        if( text.length == 0 )
        {
            return
        }
        
        let pStyle           = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        pStyle.lineBreakMode = .byTruncatingMiddle
        
        let attr = [
            NSAttributedStringKey.font:            font,
            NSAttributedStringKey.foregroundColor: color,
            NSAttributedStringKey.paragraphStyle:  pStyle
        ]
        
        var range           = NSMakeRange( 0, 1 )
        var lineRange       = NSMakeRange( 0, 1 )
        var start           = 0
        var end             = 0
        var contentsEnd     = 0
        var line            = 0
        let selectedRange   = NSMakeRange( NSNotFound, 0 )
        let glyphRange      = layoutManager.glyphRange( forBoundingRect: visibleRect, in: textContainer )
        
        while( lineRange.location < glyphRange.location )
        {
            lineRange          = text.lineRange( for: lineRange )
            lineRange.location = lineRange.location + lineRange.length
            lineRange.length   = 1
            
            line += 1
        }
        
        range.location = glyphRange.location
        
        while( range.location + range.length <= text.length )
        {
            text.getLineStart( &start, end: &end, contentsEnd: &contentsEnd, for: range )
            
            var rectCount = 0
            
            guard let rectArray = layoutManager.rectArray( forGlyphRange: range, withinSelectedGlyphRange: selectedRange, in: textContainer, rectCount: &rectCount ) else
            {
                continue
            }
            
            if( rectCount == 0 )
            {
                continue
            }
            
            var lineRect         = rectArray[ 0 ]
            lineRect.origin.x    = 2
            lineRect.origin.y   -= visibleRect.origin.y
            lineRect.origin.y   += t.textContainerInset.height / 2
            lineRect.size.width  = rect.size.width - 2
            lineRect.size.height = rect.size.height
            
            ( String( describing: line + 1 ) as NSString ).draw( in: lineRect, withAttributes: attr )
            
            range.location = end
            line          += 1
        }
    }
}
