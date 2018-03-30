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
    @objc dynamic public var paused: Bool = true
    @objc dynamic public var colors: Bool = Preferences.shared.colors
    
    @objc dynamic public private( set ) var speed: UInt    = Preferences.shared.speed
    @objc dynamic public private( set ) var fps:   CGFloat = 0
    @objc dynamic public private( set ) var grid:  Grid    = Grid( width: 0, height: 0 )
    
    public private( set ) var cellSize:      CGFloat        = 5
    private               var lastUpdate:    CFAbsoluteTime = 0
    private               var mouseUpResume: Bool           = false
    private               var timer:         Timer?
    
    init( frame rect: NSRect, kind: Grid.Kind )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / self.cellSize ), height: size_t( rect.size.height / self.cellSize ), kind: kind )
    }
    
    override init( frame rect: NSRect )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / self.cellSize ), height: size_t( rect.size.height / self.cellSize ) )
    }
    
    required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )
        
        self.grid = Grid( width: size_t( self.frame.size.width / self.cellSize ), height: size_t( self.frame.size.height / self.cellSize ) )
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
    
    private func _startTimer()
    {
        let interval = ( 20 - TimeInterval( Preferences.shared.speed ) ) / 50
        
        self.timer = Timer.scheduledTimer( timeInterval: interval, target: self, selector: #selector( next ), userInfo: nil, repeats: true )
    }
    
    private func _stopTimer()
    {
        self.timer?.invalidate()
        
        self.timer = nil
    }
    
    private func _restartTimer()
    {
        self._stopTimer()
        self._startTimer()
    }
    
    @IBAction func resume( _ sender: Any? )
    {
        if( self.paused == false )
        {
            return
        }
        
        self.paused = false
        
        self._startTimer()
    }
    
    @IBAction func pause( _ sender: Any? )
    {
        if( self.paused == true )
        {
            return
        }
        
        self._stopTimer()
        
        self.paused = true
    }
    
    @IBAction func decreaseSpeed( _ sender: Any? )
    {
        if( Preferences.shared.speed == 0 )
        {
            return
        }
        
        Preferences.shared.speed -= 1
        self.speed                = Preferences.shared.speed
        
        self._restartTimer()
    }
    
    @IBAction func increaseSpeed( _ sender: Any? )
    {
        if( Preferences.shared.speed == 20 )
        {
            return
        }
        
        Preferences.shared.speed += 1
        self.speed                = Preferences.shared.speed
        
        self._restartTimer()
    }
    
    @IBAction func toggleColors( _ sender: Any? )
    {
        self.colors               = ( self.colors ) ? false : true
        Preferences.shared.colors = self.colors
    }
    
    @objc private func next()
    {
        if( self.paused )
        {
            return
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
            
            self.lastUpdate = end
        }
    }
    
    public func colorForAge( _ age: UInt64 ) -> NSColor
    {
        if( self.colors == false )
        {
            return NSColor.white
        }
        
        if( age == 0 )
        {
            return NSColor.black
        }
        else if( age == 1 )
        {
            return Preferences.shared.color1()
        }
        else if( age == 2 )
        {
            return Preferences.shared.color2()
        }
        else if( age == 3 )
        {
            return Preferences.shared.color3()
        }
        else if( age == 4 )
        {
            return Preferences.shared.color4()
        }
        else if( age == 5 )
        {
            return Preferences.shared.color5()
        }
        
        return Preferences.shared.color6()
    }
    
    override func mouseDown( with event: NSEvent )
    {
        self.mouseUpResume = self.paused == false
        
        self.pause( nil )
        
        guard let point = self.window?.contentView?.convert( event.locationInWindow, to: self ) else
        {
            return
        }
        
        guard let cell = self.grid.cellAt( x: size_t( point.x / self.cellSize ), y: size_t( point.y / self.cellSize ) ) else
        {
            return
        }
        
        cell.isAlive = ( cell.isAlive ) ? false : true
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func mouseUp( with event: NSEvent )
    {
        if( self.mouseUpResume )
        {
            self.resume( nil )
        }
    }
    
    override func mouseDragged( with event: NSEvent )
    {
        guard let point = self.window?.contentView?.convert( event.locationInWindow, to: self ) else
        {
            return
        }
        
        guard let cell = self.grid.cellAt( x: size_t( point.x / self.cellSize ), y: size_t( point.y / self.cellSize ) ) else
        {
            return
        }
        
        cell.isAlive = true
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func draw( _ rect: NSRect )
    {
        NSColor.clear.setFill()
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
