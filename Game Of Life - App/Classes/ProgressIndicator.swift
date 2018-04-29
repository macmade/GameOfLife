/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
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

@IBDesignable class ProgressIndicator: NSView
{
    @IBInspectable @objc public dynamic var displayWhenStopped: Bool    = false
    @IBInspectable @objc public dynamic var lineWidth:          CGFloat = 5
    @IBInspectable @objc public dynamic var color1:             NSColor = NSColor( deviceWhite: 1, alpha: 0.50 )
    @IBInspectable @objc public dynamic var color2:             NSColor = NSColor( deviceWhite: 1, alpha: 0.75 )
    
    private var startAngle:   CGFloat                   = 0
    private var endAngle:     CGFloat                   = 90
    private var observations: [ NSKeyValueObservation ] = []
    private var timer:        Timer?
    
    override init( frame: NSRect )
    {
        super.init( frame: frame )
    }
    
    required init?( coder: NSCoder )
    {
        super.init( coder: coder )
    }
    
    override var allowsVibrancy: Bool
    {
        return false
    }
    
    override var isFlipped: Bool
    {
        return true
    }
    
    func startAnimation( _ sender: Any? )
    {
        if( self.timer != nil )
        {
            return
        }
        
        self.timer = Timer.scheduledTimer( withTimeInterval: 0.02, repeats: true )
        {
            ( t ) in
            
            self.startAngle += 10
            self.endAngle   += 10
            
            if( self.startAngle >= 360 )
            {
                self.startAngle -= 360
            }
            
            if( self.endAngle >= 360 )
            {
                self.endAngle -= 360
            }
            
            self.setNeedsDisplay( self.bounds )
        }
        
        self.setNeedsDisplay( self.bounds )
    }
    
    func stopAnimation( _ sender: Any? )
    {
        self.timer?.invalidate()
        
        self.timer = nil
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func draw( _ r: NSRect )
    {
        let rect = self.bounds
        
        NSColor.clear.setFill()
        rect.fill()
        
        if( self.displayWhenStopped == false && self.timer == nil )
        {
            return
        }
        
        let p1       = NSBezierPath( ovalIn: NSInsetRect( rect, lineWidth / 2, lineWidth / 2 ) )
        p1.lineWidth = self.lineWidth
        
        self.color1.setStroke()
        p1.stroke()
        
        let p2          = NSBezierPath()
        p2.lineWidth    = self.lineWidth
        p2.lineCapStyle = .roundLineCapStyle
        
        p2.appendArc( withCenter: NSPoint( x: NSMidX( rect ), y: NSMidY( rect ) ), radius: ( rect.size.width / 2 ) - ( lineWidth / 2 ), startAngle: self.startAngle, endAngle: self.endAngle )
        
        self.color2.setStroke()
        p2.stroke()
    }
}
