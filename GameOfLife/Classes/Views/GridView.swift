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

public class GridView: NSView
{
    @objc dynamic public var paused:               Bool    = true
    @objc dynamic public var resizing:             Bool    = false
    @objc dynamic public var resumeAfterOperation: Bool    = false
    @objc dynamic public var drawSetAlive:         Bool    = false
    @objc dynamic public var dragging:             Bool    = false
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

    private var panning        = false
    private var panStartPoint  = NSPoint.zero
    private var panStartOrigin = ( x: 0, y: 0 )
    
    public override var acceptsFirstResponder: Bool
    {
        return true
    }

    public init( frame rect: NSRect, kind: Grid.Kind )
    {
        super.init( frame: rect )

        let size  = GridView.gridSize( for: rect.size )
        self.grid = Grid( width: size.width, height: size.height, kind: kind )

        self.setup()
    }

    public override init( frame rect: NSRect )
    {
        super.init( frame: rect )

        let size  = GridView.gridSize( for: rect.size )
        self.grid = Grid( width: size.width, height: size.height )

        self.setup()
    }

    public required init?( coder decoder: NSCoder )
    {
        super.init( coder: decoder )

        let size  = GridView.gridSize( for: self.frame.size )
        self.grid = Grid( width: size.width, height: size.height )

        self.setup()
    }

    /// Computes the grid dimensions that fit the given view size at the current
    /// (clamped) cell size.
    private static func gridSize( for size: NSSize ) -> ( width: size_t, height: size_t )
    {
        let cellSize = CGFloat( max( 1, Preferences.shared.cellSize ) )

        return ( size_t( size.width / cellSize ), size_t( size.height / cellSize ) )
    }

    /// Shared initializer setup: preference observers, drag registration and the
    /// initial dimension update. Used by every initializer.
    private func setup()
    {
        self.observations.append( Preferences.shared.observe( \Preferences.speed    ) { ( c, o ) in self.restartTimer() } )
        self.observations.append( Preferences.shared.observe( \Preferences.cellSize ) { ( c, o ) in self.updateViewportExtent() } )
        self.registerForDraggedTypes( [ LibraryItem.PasteboardType ] )
        self.updateDimensions()
    }
    
    public override func resize( withOldSuperviewSize size: NSSize )
    {
        if( self.resizing == false )
        {
            self.resumeAfterOperation = self.paused == false
            self.resizing             = true
        }
        
        self.pause( nil )
        
        super.resize( withOldSuperviewSize: size )
    }
    
    public override func viewDidEndLiveResize()
    {
        self.updateViewportExtent()

        if( self.resumeAfterOperation )
        {
            self.resume( nil )
        }
        
        self.resumeAfterOperation = false
        self.resizing             = false
        
    }
    
    /// Resyncs the viewport's visible extent to the current view and cell size,
    /// then redraws. The cells are untouched — only the on-screen window over the
    /// unbounded plane changes (no pruning, no bounds manipulation).
    private func updateViewportExtent()
    {
        self.cellSize = CGFloat( max( 1, Preferences.shared.cellSize ) )

        let width  = size_t( ceil( self.frame.size.width  / self.cellSize ) )
        let height = size_t( ceil( self.frame.size.height / self.cellSize ) )

        self.grid.setViewport( originX: self.grid.originX, originY: self.grid.originY, width: width, height: height )

        self.setNeedsDisplay( self.bounds )
        self.updateDimensions()
    }

    public func updateDimensions()
    {
        self.cellSize = CGFloat( max( 1, Preferences.shared.cellSize ) )

        // The plane is unbounded, so report the live pattern's bounding-box size
        // rather than a fixed playfield; empty grids read as 0x0.
        guard let bounds = self.grid.liveBounds() else
        {
            self.gridDimensions = "0x0"

            return
        }

        let s1 = String( describing: bounds.maxX - bounds.minX + 1 )
        let s2 = String( describing: bounds.maxY - bounds.minY + 1 )

        self.gridDimensions = s1 + "x" + s2
    }
    
    public override var isFlipped: Bool
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
    
    @IBAction public func resume( _ sender: Any? )
    {
        if( self.paused == false )
        {
            return
        }
        
        self.paused = false
        
        self.startTimer()
    }
    
    @IBAction public func pause( _ sender: Any? )
    {
        if( self.paused == true )
        {
            return
        }
        
        self.stopTimer()
        
        self.paused = true
        self.fps    = 0
    }
    
    @IBAction public func step( _ sender: Any? )
    {
        self.grid.next()
        self.setNeedsDisplay( self.bounds )
    }
    
    @IBAction public func decreaseSpeed( _ sender: Any? )
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
    
    @IBAction public func increaseSpeed( _ sender: Any? )
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

        if( self.paused || self.grid.turns % UInt64( max( 1, skip ) ) == 0 )
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
    
    /// Maps a point in this view's (flipped) coordinates to a world cell, through
    /// the current viewport origin.
    private func worldCell( at point: NSPoint ) -> ( x: Int, y: Int )
    {
        let x = self.grid.originX + Int( floor( point.x / self.cellSize ) )
        let y = self.grid.originY + Int( floor( point.y / self.cellSize ) )

        return ( x, y )
    }

    public override func mouseDown( with event: NSEvent )
    {
        guard let point = self.window?.contentView?.convert( event.locationInWindow, to: self ) else
        {
            return
        }

        // Holding Option turns a drag into a viewport pan instead of editing.
        if( event.modifierFlags.contains( .option ) )
        {
            self.panning        = true
            self.panStartPoint  = point
            self.panStartOrigin = ( self.grid.originX, self.grid.originY )

            return
        }

        self.mouseUpResume = self.paused == false

        self.pause( nil )

        let cell = self.worldCell( at: point )

        self.drawSetAlive = self.grid.isAliveAt( x: cell.x, y: cell.y ) == false

        self.grid.setAliveAt( x: cell.x, y: cell.y, value: self.drawSetAlive )
        self.setNeedsDisplay( self.bounds )
    }

    public override func mouseUp( with event: NSEvent )
    {
        if( self.panning )
        {
            self.panning = false

            return
        }

        if( self.mouseUpResume )
        {
            self.resume( nil )
        }
    }

    public override func mouseDragged( with event: NSEvent )
    {
        guard let point = self.window?.contentView?.convert( event.locationInWindow, to: self ) else
        {
            return
        }

        if( self.panning )
        {
            let dx = Int( ( ( point.x - self.panStartPoint.x ) / self.cellSize ).rounded() )
            let dy = Int( ( ( point.y - self.panStartPoint.y ) / self.cellSize ).rounded() )

            self.grid.setViewport( originX: self.panStartOrigin.x - dx, originY: self.panStartOrigin.y - dy, width: self.grid.width, height: self.grid.height )
            self.setNeedsDisplay( self.bounds )

            return
        }

        let cell = self.worldCell( at: point )

        self.grid.setAliveAt( x: cell.x, y: cell.y, value: self.drawSetAlive )
        self.setNeedsDisplay( self.bounds )
    }
    
    public override func draw( _ rect: NSRect )
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
        
        // Render only the live cells inside the visible world rect, mapping each
        // world coordinate to a screen position through the viewport origin. The
        // bounds run one cell past the view to cover partially-visible edges.
        let originX = self.grid.originX
        let originY = self.grid.originY
        let cols    = Int( ceil( self.frame.size.width  / cellSize ) )
        let rows    = Int( ceil( self.frame.size.height / cellSize ) )

        self.grid.forEachLiveCell( inMinX: originX, minY: originY, maxX: originX + cols, maxY: originY + rows )
        {
            worldX, worldY, cell in

            if( hasColors )
            {
                let age = Int( cell >> 1 )

                if( age >= colors.count )
                {
                    colors.last?.setFill()
                }
                else
                {
                    colors[ age ].setFill()
                }
            }
            else
            {
                NSColor.white.setFill()
            }

            let rect = NSRect( x: cellSize * CGFloat( worldX - originX ), y: cellSize * CGFloat( worldY - originY ), width: cellSize, height: cellSize )

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
        
        cells.enumerated().forEach
        {
            i, s in

            ( 0 ..< s.count ).forEach
            {
                j in

                let c = s[ String.Index( utf16Offset: j, in: s ) ]

                if( c == " " )
                {
                    return
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
    
    public override func draggingEntered( _ sender: NSDraggingInfo ) -> NSDragOperation
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
    
    public override func draggingUpdated( _ sender: NSDraggingInfo ) -> NSDragOperation
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
    
    public override func draggingExited( _ sender: NSDraggingInfo? )
    {
        self.endDrag()
    }

    public override func draggingEnded( _ sender: NSDraggingInfo )
    {
        self.endDrag()
        self.window?.makeFirstResponder( self )
    }

    /// Clears the in-progress drag state, resumes the simulation if it was only
    /// paused for the drag, and requests a redraw. Shared by the drag-exit and
    /// drag-end handlers.
    private func endDrag()
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
    
    public override func performDragOperation( _ sender: NSDraggingInfo ) -> Bool
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
            item.prepareRotations()

            guard self.draggedRotation <= item.rotations.count else
            {
                return false
            }

            cells = item.rotations[ self.draggedRotation - 1 ]
        }
        
        let point     = self.convert( sender.draggingLocation, from: self.window?.contentView )
        let cellSize  = self.cellSize

        // Drop into world coordinates, through the viewport origin.
        let offsetX = self.grid.originX + Int( ceil( point.x / cellSize ) )
        let offsetY = self.grid.originY + Int( ceil( point.y / cellSize ) )

        self.grid.add( cells: cells, left: offsetX, top: offsetY )
        
        self.setNeedsDisplay( self.bounds )
        
        return true
    }
}
