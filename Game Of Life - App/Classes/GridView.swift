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

class GridView: NSView
{
    public private( set ) var grid:       Grid           = Grid( width: 0, height: 0 )
    public private( set ) var cellSize:   CGFloat        = 5
    private               var title:      NSString       = ""
    private               var lastUpdate: CFAbsoluteTime = 0;
    private               var timer:      Timer?
    
    override init( frame rect: NSRect )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / self.cellSize ), height: size_t( rect.size.height / self.cellSize ) )
    }
    
    required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )
        
        self.grid = Grid( width: size_t( self.frame.size.width / self.cellSize ), height: size_t( self.frame.size.height / self.cellSize ), kind: .GospersGuns )
    }
    
    override func resize( withOldSuperviewSize size: NSSize )
    {
        super.resize( withOldSuperviewSize: size )
        self.grid.resize( width: size_t( self.frame.size.width / self.cellSize ), height: size_t( self.frame.size.height / self.cellSize ) )
    }
    
    override var isFlipped: Bool
    {
        return true
    }
    
    public func start()
    {
        self.timer = Timer.scheduledTimer( timeInterval: 0, target: self, selector: #selector( next ), userInfo: nil, repeats: true )
    }
    
    @objc private func next()
    {
        if( self.title.length == 0 )
        {
            self.title = ( self.window?.title ?? "" ) as NSString
        }
        
        self.grid.next()
        
        self.setNeedsDisplay( self.bounds )
        
        if( self.lastUpdate == 0 )
        {
            self.lastUpdate = CFAbsoluteTimeGetCurrent()
        }
        else
        {
            let end = CFAbsoluteTimeGetCurrent()
            
            self.window?.title = self.title as String + " | " + String( ( 1 / ( end - self.lastUpdate ) ).rounded() ) + " FPS"
            
            self.lastUpdate = end
        }
    }
    
    public func colorForAge( _ age: UInt64 ) -> NSColor
    {
        if( age == 0 )
        {
            return NSColor( hex: 0x000000, alpha: 0 )
        }
        else if( age == 1 )
        {
            return NSColor( hex: 0xB37D49, alpha: 1 )
        }
        else if( age == 2 )
        {
            return NSColor( hex: 0xA39C39, alpha: 1 )
        }
        else if( age == 3 )
        {
            return NSColor( hex: 0x6C884D, alpha: 1 )
        }
        else if( age == 4 )
        {
            return NSColor( hex: 0x6FAFAF, alpha: 1 )
        }
        else if( age == 5 )
        {
            return NSColor( hex: 0x678CB1, alpha: 1 )
        }
        
        return NSColor( hex: 0xA082BD, alpha: 1 )
    }
    
    override func draw( _ rect: NSRect )
    {
        NSColor( hex: 0x161A1D ).setFill()
        NSRectFill( self.frame )
        
        for i in 0 ..< size_t( self.frame.size.height / self.cellSize )
        {
            for j in 0 ..< size_t( self.frame.size.width / self.cellSize )
            {
                guard let cell = self.grid.cellAt( x: j, y: i ) else
                {
                    continue
                }
                
                if( cell.isAlive )
                {
                    self.colorForAge( cell.age ).setFill()
                    NSRectFill( NSRect( x: self.cellSize * CGFloat( j ), y: self.cellSize * CGFloat( i ), width: self.cellSize, height: self.cellSize ) )
                }
            }
        }
    }
}
