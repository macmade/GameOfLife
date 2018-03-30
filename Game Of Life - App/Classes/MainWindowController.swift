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

class MainWindowController: NSWindowController
{
    @objc dynamic public var paused: Bool = false
    
    @IBOutlet private var gridViewContainer: NSView?
    @objc     private var gridView:          GridView?
    
    override var windowNibName: String?
    {
        return NSStringFromClass( type( of: self ) )
    }
    
    override func windowDidLoad()
    {
        self.createNewGridView( kind: .Random )
    }
    
    func createNewGridView( kind: Grid.Kind )
    {
        guard let container = self.gridViewContainer else
        {
            return
        }
        
        self.gridView?.pause( nil )
        self.gridView?.removeFromSuperview()
        
        let gridView  = GridView( frame: container.bounds, kind: kind )
        self.gridView = gridView
        
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview( gridView )
        container.addConstraint( NSLayoutConstraint( item: gridView, attribute: .width,   relatedBy: .equal, toItem: container, attribute: .width,   multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: gridView, attribute: .height,  relatedBy: .equal, toItem: container, attribute: .height,  multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: gridView, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0 ) )
        container.addConstraint( NSLayoutConstraint( item: gridView, attribute: .centerY, relatedBy: .equal, toItem: container, attribute: .centerY, multiplier: 1, constant: 0 ) )
        
        if( self.paused == false )
        {
            self.gridView?.resume( nil )
        }
    }
    
    @IBAction func showMenu( _ sender: Any? )
    {
        guard let button = sender as? NSButton else
        {
            return
        }
        
        guard let event = NSApp.currentEvent else
        {
            return
        }
        
        guard let menu = button.menu else
        {
            return
        }
        
        NSMenu.popUpContextMenu( menu, with: event, for: button )
    }
    
    @IBAction func resume( _ sender: Any? )
    {
        self.gridView?.resume( sender )
        
        self.paused = false
    }
    
    @IBAction func pause( _ sender: Any? )
    {
        self.gridView?.pause( sender )
        
        self.paused = true;
    }
    
    @IBAction func pauseResume( _ sender: Any? )
    {
        if( self.paused )
        {
            self.resume( sender )
        }
        else
        {
            self.pause( sender )
        }
    }
    
    @IBAction func decreaseSpeed( _ sender: Any? )
    {
        self.gridView?.decreaseSpeed( sender )
    }
    
    @IBAction func increaseSpeed( _ sender: Any? )
    {
        self.gridView?.increaseSpeed( sender )
    }
    
    @IBAction func createBlankGrid( _ sender: Any? )
    {
        self.createNewGridView( kind: .Blank )
    }
    
    @IBAction func createRandomGrid( _ sender: Any? )
    {
        self.createNewGridView( kind: .Random )
    }
    
    @IBAction func createExampleGrid1( _ sender: Any? )
    {
        self.createNewGridView( kind: .StillLife )
    }
    
    @IBAction func createExampleGrid2( _ sender: Any? )
    {
        self.createNewGridView( kind: .Oscillators )
    }
    
    @IBAction func createExampleGrid3( _ sender: Any? )
    {
        self.createNewGridView( kind: .Spaceships )
    }
    
    @IBAction func createExampleGrid4( _ sender: Any? )
    {
        self.createNewGridView( kind: .GospersGuns )
    }
    
    @IBAction func toggleColors( _ sender: Any? )
    {
        self.gridView?.toggleColors( sender )
    }
}
