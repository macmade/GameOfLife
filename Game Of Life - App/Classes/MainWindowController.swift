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
    @objc dynamic public var paused:         Bool = false
    @objc dynamic public var showLibrary:    Bool = false
    @objc dynamic public var hideControls:   Bool = false
    
    @objc public private( set ) dynamic var gridView: GridView?
    
    @IBOutlet private var gridViewContainer:    NSView?
    @IBOutlet private var libraryViewContainer: NSView?
    
    @objc dynamic public private( set ) var libraryViewController: LibraryViewController?
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        self.createNewGridView( kind: .Random )
        self.toggleLibrary( nil )
        self.window?.makeFirstResponder( self.gridView )
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
    
    @IBAction func step( _ sender: Any? )
    {
        self.pause( sender )
        self.gridView?.step( sender )
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
    
    @IBAction func toggleColors( _ sender: Any? )
    {
        Preferences.shared.colors = ( Preferences.shared.colors ) ? false : true
    }
    
    @IBAction func toggleShapes( _ sender: Any? )
    {
        Preferences.shared.drawAsSquares = ( Preferences.shared.drawAsSquares ) ? false : true
    }
    
    @IBAction func openDocument( _ sender: Any? )
    {
        self.pause( sender )
        
        let panel                  = NSOpenPanel()
        panel.canCreateDirectories = false
        panel.allowedFileTypes     = [ "gol" ]
        panel.canChooseDirectories = false
        panel.canChooseFiles       = true
        
        guard let window = self.window else
        {
            return
        }
        
        panel.beginSheetModal( for: window )
        {
            res in
            
            if( res != .OK )
            {
                return
            }
            
            guard let url = panel.url else
            {
                return
            }
            
            guard let data = NSData( contentsOf: url ) else
            {
                return
            }
            
            if( self.gridView?.grid.load( data: data as Data ) == false )
            {
                let alert             = NSAlert()
                alert.messageText     = "Error"
                alert.informativeText = "Unable to load save file - Incorrect data"
                
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
            else
            {
                self.gridView?.setNeedsDisplay( self.gridView!.bounds )
                self.gridView?.updateDimensions()
            }
        }
    }
    
    @IBAction func saveDocument( _ sender: Any? )
    {
        self.saveDocumentAs( sender )
    }
    
    @IBAction func saveDocumentAs( _ sender: Any? )
    {
        self.pause( sender )
        
        let panel                  = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedFileTypes     = [ "gol" ]
        
        guard let window = self.window else
        {
            return
        }
        
        guard let data = self.gridView?.grid.data() else
        {
            return
        }
        
        panel.beginSheetModal( for: window )
        {
            res in
            
            if( res != .OK )
            {
                return
            }
            
            guard let url = panel.url else
            {
                return
            }
            
            do
            {
                try data.write( to: url, options: .atomic )
            }
            catch let error as NSError
            {
                NSAlert( error: error ).beginSheetModal( for: window, completionHandler: nil )
            }
        }
    }
    
    @IBAction func toggleControls( _ sender: Any? )
    {
        self.hideControls = self.hideControls == false
    }
    
    @IBAction func toggleLibrary( _ sender: Any? )
    {
        if( self.libraryViewController == nil )
        {
            self.libraryViewController = LibraryViewController()
            
            guard let container = self.libraryViewContainer else
            {
                return
            }
            
            guard let view = self.libraryViewController?.view else
            {
                return
            }
            
            view.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview( view )
            container.addConstraint( NSLayoutConstraint( item: view, attribute: .width,   relatedBy: .equal, toItem: container, attribute: .width,   multiplier: 1, constant: 0 ) )
            container.addConstraint( NSLayoutConstraint( item: view, attribute: .height,  relatedBy: .equal, toItem: container, attribute: .height,  multiplier: 1, constant: 0 ) )
            container.addConstraint( NSLayoutConstraint( item: view, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0 ) )
            container.addConstraint( NSLayoutConstraint( item: view, attribute: .centerY, relatedBy: .equal, toItem: container, attribute: .centerY, multiplier: 1, constant: 0 ) )
        }
        
        self.showLibrary = self.showLibrary == false
    }
}
