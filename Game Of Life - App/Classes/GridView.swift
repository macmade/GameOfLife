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
    @objc dynamic public var paused:               Bool = true
    @objc dynamic public var resizing:             Bool = false
    @objc dynamic public var resumeAfterOperation: Bool = false
    
    @objc dynamic public private( set ) var speed: UInt    = Preferences.shared.speed
    @objc dynamic public private( set ) var fps:   CGFloat = 0
    @objc dynamic public private( set ) var grid:  Grid    = Grid( width: 0, height: 0 )
    
    private var lastUpdate:    CFAbsoluteTime            = 0
    private var mouseUpResume: Bool                      = false
    private var observations:  [ NSKeyValueObservation ] = []
    private var timer:         Timer?
    private var draggedItem:   LibraryItem?
    private var draggedPoint:  NSPoint?
    
    init( frame rect: NSRect, kind: Grid.Kind )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / Preferences.shared.cellSize ), height: size_t( rect.size.height / Preferences.shared.cellSize ), kind: kind )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
    }
    
    override init( frame rect: NSRect )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / Preferences.shared.cellSize ), height: size_t( rect.size.height / Preferences.shared.cellSize ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
    }
    
    required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )
        
        self.grid = Grid( width: size_t( self.frame.size.width / Preferences.shared.cellSize ), height: size_t( self.frame.size.height / Preferences.shared.cellSize ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self._restartTimer() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
    }
    
    override func resize( withOldSuperviewSize size: NSSize )
    {
        if( self.resizing == false )
        {
            self.resumeAfterOperation = self.paused == false
            self.resizing             = true
        }
        
        self.pause( nil )
        
        super.resize( withOldSuperviewSize: size )
    }
    
    override func viewDidEndLiveResize()
    {
        self.grid.resize( width: size_t( self.frame.size.width / Preferences.shared.cellSize ), height: size_t( self.frame.size.height / Preferences.shared.cellSize ) )
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        self.resizing             = false
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override var isFlipped: Bool
    {
        return true
    }
    
    private func _startTimer()
    {
        self.speed   = Preferences.shared.speed
        let interval = ( ( 20 - TimeInterval( Preferences.shared.speed ) ) / 50 )
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
    
    @IBAction func step( _ sender: Any? )
    {
        self.grid.next()
        self.setNeedsDisplay( self.bounds )
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
        
        let cellSize  = Preferences.shared.cellSize
        let hasColors = Preferences.shared.colors
        let colors    = [
                            Preferences.shared.color1(),
                            Preferences.shared.color2(),
                            Preferences.shared.color3(),
                            Preferences.shared.color4(),
                            Preferences.shared.color5(),
                            Preferences.shared.color6()
                        ]
        
        for x in 0 ..< size_t( self.frame.size.width / Preferences.shared.cellSize )
        {
            for y in 0 ..< size_t( self.frame.size.height / Preferences.shared.cellSize )
            {
                if( x >= self.grid.width || y >= self.grid.height )
                {
                    continue
                }
                
                let cell = self.grid.cells[ x + ( y * self.grid.width ) ]
                
                if( cell & 1 == 0 )
                {
                    continue
                }
                
                if( hasColors )
                {
                    let age = cell >> 1
                    
                    if( age >= colors.count )
                    {
                        colors.last?.setFill()
                    }
                    else
                    {
                        colors[ size_t( age ) ].setFill()
                    }
                }
                else
                {
                    NSColor.white.setFill()
                }
                
                NSRect( x: cellSize * CGFloat( x ), y: cellSize * CGFloat( y ), width: cellSize, height: cellSize ).fill()
            }
        }
        
        guard let cells = self.draggedItem?.cells else
        {
            return
        }
        
        guard let p = self.draggedPoint else
        {
            return
        }
        
        let point = self.convert( p, from: self.window?.contentView )
        
        for i in 0 ..< cells.count
        {
            let s = cells[ i ]
            
            for j in 0 ..< s.count
            {
                let c = s[ String.Index( encodedOffset: j ) ]
                
                if( c == " " )
                {
                    continue
                }
                
                var x = CGFloat( j ) * cellSize
                var y = CGFloat( i ) * cellSize
                
                x += cellSize * ceil( ceil( point.x ) / cellSize )
                y += cellSize * ceil( ceil( point.y ) / cellSize )
                
                let rect = NSRect( x: x, y: y, width: cellSize, height: cellSize )
                
                NSColor( calibratedWhite: 1, alpha: 0.75 ).setFill()
                rect.fill()
            }
        }
    }
    
    override func draggingEntered( _ sender: NSDraggingInfo ) -> NSDragOperation
    {
        guard let objects = sender.draggingPasteboard().readObjects( forClasses: [ LibraryItem.self ], options: nil ) as? [ LibraryItem ] else
        {
            return .generic
        }
        
        guard let item = objects.first else
        {
            return .generic
        }
        
        self.resumeAfterOperation = self.paused == false
        self.draggedItem          = item
        self.draggedPoint         = sender.draggingLocation()
        
        self.pause( nil )
        self.setNeedsDisplay( self.bounds )
        
        return .copy
    }
    
    override func draggingUpdated( _ sender: NSDraggingInfo ) -> NSDragOperation
    {
        guard let objects = sender.draggingPasteboard().readObjects( forClasses: [ LibraryItem.self ], options: nil ) as? [ LibraryItem ] else
        {
            return .generic
        }
        
        guard let item = objects.first else
        {
            return .generic
        }
        
        self.draggedItem  = item
        self.draggedPoint = sender.draggingLocation()
        
        self.setNeedsDisplay( self.bounds )
        
        return .copy
    }
    
    override func draggingExited( _ sender: NSDraggingInfo? )
    {
        self.draggedItem  = nil
        self.draggedPoint = nil
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func draggingEnded( _ sender: NSDraggingInfo )
    {
        self.draggedItem  = nil
        self.draggedPoint = nil
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func performDragOperation( _ sender: NSDraggingInfo ) -> Bool
    {
        guard let objects = sender.draggingPasteboard().readObjects( forClasses: [ LibraryItem.self ], options: nil ) as? [ LibraryItem ] else
        {
            return false
        }
        
        guard let cells = objects.first?.cells else
        {
            return false
        }
        
        let point     = self.convert( sender.draggingLocation(), from: self.window?.contentView )
        let cellSize  = Preferences.shared.cellSize
        
        let offsetX = Int( ceil( point.x / cellSize ) );
        let offsetY = Int( ceil( point.y / cellSize ) );
        
        for i in 0 ..< cells.count
        {
            let s = cells[ i ]
            
            for j in 0 ..< s.count
            {
                let c = s[ String.Index( encodedOffset: j ) ]
                
                if( c == " " )
                {
                    continue
                }
                
                self.grid.setAliveAt( x: j + offsetX, y: i + offsetY, value: true )
            }
        }
        
        self.setNeedsDisplay( self.bounds )
        
        return true
    }
}
