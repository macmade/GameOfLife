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
    @objc dynamic public var paused:            Bool = true
    @objc dynamic public var resizing:          Bool = false
    @objc dynamic public var resumeAfterResize: Bool = false
    
    @objc dynamic public private( set ) var speed: UInt    = Preferences.shared.speed
    @objc dynamic public private( set ) var fps:   CGFloat = 0
    @objc dynamic public private( set ) var grid:  Grid    = Grid( width: 0, height: 0 )
    
    private var lastUpdate:    CFAbsoluteTime            = 0
    private var mouseUpResume: Bool                      = false
    private var observations:  [ NSKeyValueObservation ] = []
    private var timer:         Timer?
    
    init( frame rect: NSRect, kind: Grid.Kind )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / Preferences.shared.cellSize ), height: size_t( rect.size.height / Preferences.shared.cellSize ), kind: kind )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
    }
    
    override init( frame rect: NSRect )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / Preferences.shared.cellSize ), height: size_t( rect.size.height / Preferences.shared.cellSize ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
    }
    
    required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )
        
        self.grid = Grid( width: size_t( self.frame.size.width / Preferences.shared.cellSize ), height: size_t( self.frame.size.height / Preferences.shared.cellSize ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
    }
    
    override func resize( withOldSuperviewSize size: NSSize )
    {
        if( self.resizing == false )
        {
            self.resumeAfterResize = self.paused == false
            self.resizing          = true
        }
        
        self.pause( nil )
        
        super.resize( withOldSuperviewSize: size )
    }
    
    override func viewDidEndLiveResize()
    {
        self.grid.resize( width: size_t( self.frame.size.width / Preferences.shared.cellSize ), height: size_t( self.frame.size.height / Preferences.shared.cellSize ) )
        
        if( self.resumeAfterResize )
        {
            self.resume( nil )
        }
        
        self.resumeAfterResize = false
        self.resizing          = false
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override var isFlipped: Bool
    {
        return true
    }
    
    private func _startTimer()
    {
        self.speed   = Preferences.shared.speed
        let interval = ( 20 - TimeInterval( Preferences.shared.speed ) ) / 50
        self.timer   = Timer.scheduledTimer( timeInterval: interval, target: self, selector: #selector( next ), userInfo: nil, repeats: true )
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
        if( Preferences.shared.colors == false )
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
        
        let x = size_t( point.x / Preferences.shared.cellSize )
        let y = size_t( point.y / Preferences.shared.cellSize )
        
        self.grid.setAliveAt( x: x, y: y, value: self.grid.isAliveAt( x: x, y: y ) == false )
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
        
        let x = size_t( point.x / Preferences.shared.cellSize )
        let y = size_t( point.y / Preferences.shared.cellSize )
        
        self.grid.setAliveAt( x: x, y: y, value: true )
        self.setNeedsDisplay( self.bounds )
    }
    
    override func draw( _ rect: NSRect )
    {
        NSColor.clear.setFill()
        self.frame.fill()
        
        if( self.resizing )
        {
            return
        }
        
        for x in 0 ..< size_t( self.frame.size.width / Preferences.shared.cellSize )
        {
            for y in 0 ..< size_t( self.frame.size.height / Preferences.shared.cellSize )
            {
                if( self.grid.isAliveAt( x: x, y: y ) )
                {
                    self.colorForAge( self.grid.ageAt( x: x, y: y ) ).setFill()
                    NSRect( x: Preferences.shared.cellSize * CGFloat( x ), y: Preferences.shared.cellSize * CGFloat( y ), width: Preferences.shared.cellSize, height: Preferences.shared.cellSize ).fill()
                }
            }
        }
    }
}
