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
    @objc dynamic public var paused:               Bool    = true
    @objc dynamic public var resizing:             Bool    = false
    @objc dynamic public var resumeAfterOperation: Bool    = false
    @objc dynamic public var drawSetAlive:         Bool    = false
    @objc dynamic public var dragging:             Bool    = false
    @objc dynamic public var scale:                Int     = 0
    @objc dynamic public var cellSize:             CGFloat = 0
    @objc dynamic public var gridDimensions:       String  = ""
    
    @objc dynamic public private( set ) var speed: UInt    = Preferences.shared.speed
    @objc dynamic public private( set ) var fps:   CGFloat = 0
    @objc dynamic public private( set ) var grid:  Grid    = Grid( width: 0, height: 0 )
    
    private var lastUpdate:      CFAbsoluteTime            = 0
    private var draggedRotation: Int                       = 0
    private var mouseUpResume:   Bool                      = false
    private var observations:    [ NSKeyValueObservation ] = []
    private var timer:           Timer?
    private var draggedItem:     LibraryItem?
    private var draggedPoint:    NSPoint?
    private var dragOperation:   NSDragOperation?
    
    override var acceptsFirstResponder: Bool
    {
        return true
    }
    
    init( frame rect: NSRect, kind: Grid.Kind )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / CGFloat( Preferences.shared.cellSize ) ), height: size_t( rect.size.height / CGFloat( Preferences.shared.cellSize ) ), kind: kind )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed    ) { ( c, o ) in self.restartTimer() } )
        self.observations.append( Preferences.shared.observe( \Preferences.cellSize ) { ( c, o ) in self.resizeGrid() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
        self.updateDimensions()
    }
    
    override init( frame rect: NSRect )
    {
        super.init( frame: rect )
        
        self.grid = Grid( width: size_t( rect.size.width / CGFloat( Preferences.shared.cellSize ) ), height: size_t( rect.size.height / CGFloat( Preferences.shared.cellSize ) ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self.restartTimer() } )
        self.observations.append( Preferences.shared.observe( \Preferences.cellSize ) { ( c, o ) in self.resizeGrid() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
        self.updateDimensions()
    }
    
    required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )
        
        self.grid = Grid( width: size_t( self.frame.size.width / CGFloat( Preferences.shared.cellSize ) ), height: size_t( self.frame.size.height / CGFloat( Preferences.shared.cellSize ) ) )
        
        self.observations.append( Preferences.shared.observe( \Preferences.speed ) { ( c, o ) in self.restartTimer() } )
        self.observations.append( Preferences.shared.observe( \Preferences.cellSize ) { ( c, o ) in self.resizeGrid() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
        self.updateDimensions()
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
        self.resizeGrid()
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        self.resizing             = false
        
    }
    
    private func resizeGrid()
    {
        self.cellSize = CGFloat( Preferences.shared.cellSize )
        
        var width  = size_t( self.frame.size.width  / self.cellSize )
        var height = size_t( self.frame.size.height / self.cellSize )
        
        if( Preferences.shared.preserveGridSize )
        {
            width  = ( width  > self.grid.width  ) ? width  : self.grid.width
            height = ( height > self.grid.height ) ? height : self.grid.height
        }
        
        self.grid.resize( width: width, height: height )
        
        if( width >= self.grid.width && height >= self.grid.height )
        {
            self.setBoundsOrigin( NSMakePoint( 0, 0 ) )
            self.setBoundsSize( NSMakeSize( 0, 0 ) )
        }
        
        self.setNeedsDisplay( self.bounds )
        self.updateDimensions()
    }
    
    public func updateDimensions()
    {
        self.cellSize = CGFloat( Preferences.shared.cellSize )
        
        let s1 = String( describing: self.grid.width )
        let s2 = String( describing: self.grid.height )
        
        self.gridDimensions = s1 + "x" + s2
    }
    
    override var isFlipped: Bool
    {
        return true
    }
    
    private func startTimer()
    {
        if( self.timer != nil )
        {
            return
        }
        
        self.speed   = Preferences.shared.speed
        let interval = 1 / exp( ( TimeInterval( Preferences.shared.speed ) - 1 ) )
        self.timer   = Timer.scheduledTimer( timeInterval: interval, target: self, selector: #selector( next ), userInfo: nil, repeats: true )
    }
    
    private func stopTimer()
    {
        self.timer?.invalidate()
        
        self.timer = nil
    }
    
    private func restartTimer()
    {
        self.stopTimer()
        self.startTimer()
    }
    
    @IBAction func resume( _ sender: Any? )
    {
        if( self.paused == false )
        {
            return
        }
        
        self.paused = false
        
        self.startTimer()
    }
    
    @IBAction func pause( _ sender: Any? )
    {
        if( self.paused == true )
        {
            return
        }
        
        self.stopTimer()
        
        self.paused = true
        self.fps    = 0
    }
    
    @IBAction func step( _ sender: Any? )
    {
        self.grid.next()
        self.setNeedsDisplay( self.bounds )
    }
    
    @IBAction func decreaseSpeed( _ sender: Any? )
    {
        if( Preferences.shared.speed == 1 )
        {
            NSSound.beep()
            
            return
        }
        
        Preferences.shared.speed -= 1
        self.speed                = Preferences.shared.speed
        
        self.restartTimer()
    }
    
    @IBAction func increaseSpeed( _ sender: Any? )
    {
        if( Preferences.shared.speed == 10 )
        {
            NSSound.beep()
            
            return
        }
        
        Preferences.shared.speed += 1
        self.speed                = Preferences.shared.speed
        
        self.restartTimer()
    }
    
    @objc private func next()
    {
        if( self.paused )
        {
            return
        }
        
        self.grid.next()
        
        let skip = Preferences.shared.drawInterval
        
        if( self.paused || self.grid.turns % UInt64( skip ) == 0 )
        {
            self.display()
        }
        
        if( self.lastUpdate == 0 )
        {
            self.lastUpdate = CFAbsoluteTimeGetCurrent()
        }
        else
        {
            let end = CFAbsoluteTimeGetCurrent()
            
            self.fps = ceil( ( 1 / CGFloat( end - self.lastUpdate ) ) * 100 ) / 100
            
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
        
        let x = size_t( point.x / self.cellSize )
        let y = size_t( point.y / self.cellSize )
        
        self.drawSetAlive = self.grid.isAliveAt( x: x, y: y ) == false
        
        self.grid.setAliveAt( x: x, y: y, value: self.drawSetAlive )
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
        
        let x = size_t( point.x / self.cellSize )
        let y = size_t( point.y / self.cellSize )
        
        self.grid.setAliveAt( x: x, y: y, value: self.drawSetAlive )
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
        
        let squares   = Preferences.shared.drawAsSquares
        let cellSize  = self.cellSize
        let hasColors = Preferences.shared.colors
        let colors    = [
                            Preferences.shared.color1(),
                            Preferences.shared.color2(),
                            Preferences.shared.color3(),
                            Preferences.shared.color4(),
                            Preferences.shared.color5(),
                            Preferences.shared.color6()
                        ]
        
        for x in 0 ..< size_t( self.frame.size.width / self.cellSize )
        {
            for y in 0 ..< size_t( self.frame.size.height / self.cellSize )
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
                
                let rect = NSRect( x: cellSize * CGFloat( x ), y: cellSize * CGFloat( y ), width: cellSize, height: cellSize )
                
                if( squares || cellSize < 2 )
                {
                    rect.fill()
                }
                else
                {
                    let path = NSBezierPath( roundedRect: rect, xRadius: cellSize / 2, yRadius: cellSize / 2 )
                    
                    path.fill()
                }
            }
        }
        
        guard let item = self.draggedItem else
        {
            return
        }
        
        guard let p = self.draggedPoint else
        {
            return
        }
        
        let point = self.convert( p, from: self.window?.contentView )
        
        self.drawItemBackground( item, at: point )
        self.drawItem( item, at: point )
    }
    
    public func drawItemBackground( _ item: LibraryItem, at point: NSPoint )
    {
        let cellSize  = self.cellSize
        
        let x = cellSize * ceil( ceil( point.x ) / cellSize )
        let y = cellSize * ceil( ceil( point.y ) / cellSize )
        var w = cellSize * CGFloat( item.width )
        var h = cellSize * CGFloat( item.height )
        
        if( self.draggedRotation % 2 != 0 )
        {
            swap( &w, &h )
        }
        
        let rect = NSRect( x: x, y: y, width: w, height: h )
        let path = NSBezierPath( roundedRect: rect, xRadius: cellSize, yRadius: cellSize )
        
        NSColor( deviceWhite: 1, alpha: 0.1 ).setFill()
        path.fill()
    }
    
    public func drawItem( _ item: LibraryItem, at point: NSPoint )
    {
        let squares   = Preferences.shared.drawAsSquares
        let cellSize  = self.cellSize
        
        guard let cells = ( self.draggedRotation == 0 ) ? item.cells : ( ( self.draggedRotation <= item.rotations.count ) ? item.rotations[ self.draggedRotation - 1 ] : nil ) else
        {
            return
        }
        
        for i in 0 ..< cells.count
        {
            let s = cells[ i ]
            
            for j in 0 ..< s.count
            {
                let c = s[ String.Index( utf16Offset: j, in: s ) ]
                
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
                
                if( squares || cellSize < 2 )
                {
                    rect.fill()
                }
                else
                {
                    let path = NSBezierPath( roundedRect: rect, xRadius: cellSize / 2, yRadius: cellSize / 2 )
                    
                    path.fill()
                }
            }
        }
    }
    
    override func scrollWheel( with event: NSEvent )
    {
        if( event.modifierFlags.contains( NSEvent.ModifierFlags.option ) )
        {
            self.setBoundsOrigin( NSMakePoint( 0, 0 ) )
            self.setBoundsSize( NSMakeSize( 0, 0 ) )
            
            self.scale = 0
        }
        else if( event.modifierFlags.contains( NSEvent.ModifierFlags.command ) )
        {
            if( event.deltaY < 0 )
            {
                self.scaleUnitSquare( to: NSMakeSize( 1.1, 1.1 ) )
                
                self.scale += 1
            }
            else if ( event.deltaY > 0 && self.scale > 0 )
            {
                self.scaleUnitSquare( to: NSMakeSize( 0.9, 0.9 ) )
                
                self.scale -= 1
            }
            else if( self.scale == 0 )
            {
                self.setBoundsOrigin( NSMakePoint( 0, 0 ) )
                self.setBoundsSize( NSMakeSize( 0, 0 ) )
            }
        }
        else
        {
            if( self.scale > 0 )
            {
                if( event.deltaY > 0 )
                {
                    self.translateOrigin( to: NSMakePoint( 0, 10 ) )
                }
                else if ( event.deltaY < 0 )
                {
                    self.translateOrigin( to: NSMakePoint( 0, -10 ) )
                }
                
                if( event.deltaX > 0 )
                {
                    self.translateOrigin( to: NSMakePoint( 10, 0 ) )
                }
                else if ( event.deltaX < 0 )
                {
                    self.translateOrigin( to: NSMakePoint( -10, 0 ) )
                }
            }
        }
    }
    
    override func draggingEntered( _ sender: NSDraggingInfo ) -> NSDragOperation
    {
        guard let objects = sender.draggingPasteboard.readObjects( forClasses: [ LibraryItem.self ], options: nil ) as? [ LibraryItem ] else
        {
            return .generic
        }
        
        guard let item = objects.first else
        {
            return .generic
        }
        
        item.prepareRotations
        {
            self.setNeedsDisplay( self.bounds )
        }
        
        self.resumeAfterOperation = self.paused == false
        self.draggedItem          = item
        self.draggedPoint         = sender.draggingLocation
        self.dragging             = true
        self.draggedRotation      = 0
        
        self.pause( nil )
        self.setNeedsDisplay( self.bounds )
        
        return .copy
    }
    
    override func draggingUpdated( _ sender: NSDraggingInfo ) -> NSDragOperation
    {
        guard let item = self.draggedItem else
        {
            return .generic
        }
        
        self.draggedItem  = item
        self.draggedPoint = sender.draggingLocation
        
        self.setNeedsDisplay( self.bounds )
        
        if( self.dragOperation != NSDragOperation.generic && sender.draggingSourceOperationMask == NSDragOperation.generic )
        {
            self.draggedRotation = ( self.draggedRotation == 3 ) ? 0 : self.draggedRotation + 1
        }
        else if( self.dragOperation != NSDragOperation.copy && sender.draggingSourceOperationMask == NSDragOperation.copy )
        {
            self.draggedRotation = ( self.draggedRotation == 0 ) ? 3 : self.draggedRotation - 1
        }
        
        self.dragOperation = sender.draggingSourceOperationMask
        
        return .copy
    }
    
    override func draggingExited( _ sender: NSDraggingInfo? )
    {
        self.draggedItem     = nil
        self.draggedPoint    = nil
        self.dragOperation   = nil
        self.dragging        = false
        self.draggedRotation = 0
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        
        self.setNeedsDisplay( self.bounds )
    }
    
    override func draggingEnded( _ sender: NSDraggingInfo )
    {
        self.draggedItem     = nil
        self.draggedPoint    = nil
        self.dragOperation   = nil
        self.dragging        = false
        self.draggedRotation = 0
        
        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        
        self.setNeedsDisplay( self.bounds )
        self.window?.makeFirstResponder( self )
    }
    
    override func performDragOperation( _ sender: NSDraggingInfo ) -> Bool
    {
        guard let item = self.draggedItem else
        {
            return false
        }
        
        var cells: [ String ]
        
        if( self.draggedRotation == 0 )
        {
            cells = item.cells
        }
        else
        {
            while item.rotations.count < self.draggedRotation
            {}
            
            cells = item.rotations[ self.draggedRotation - 1 ]
        }
        
        let point     = self.convert( sender.draggingLocation, from: self.window?.contentView )
        let cellSize  = self.cellSize
        
        let offsetX = Int( ceil( point.x / cellSize ) );
        let offsetY = Int( ceil( point.y / cellSize ) );
        
        self.grid.add( cells: cells, left: offsetX, top: offsetY )
        
        self.setNeedsDisplay( self.bounds )
        
        return true
    }
}
