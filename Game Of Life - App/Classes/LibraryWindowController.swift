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

class LibraryWindowController: NSWindowController
{
    @IBOutlet private var textView: NSTextView?
    
    private var url: URL?
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        let ruler = RulerView()
        
        self.textView?.enclosingScrollView?.verticalRulerView             = ruler
        self.textView?.enclosingScrollView?.verticalRulerView             = RulerView()
        self.textView?.enclosingScrollView?.verticalRulerView?.clientView = self.textView
        self.textView?.enclosingScrollView?.hasVerticalRuler              = true
        self.textView?.enclosingScrollView?.rulersVisible                 = true
        
        self.textView?.isAutomaticQuoteSubstitutionEnabled = false
        self.textView?.textColor                           = NSColor.init( hex: 0xB2B2B2 )
        self.textView?.textContainerInset                  = NSSize( width: 10, height: 10 )
        self.textView?.font                                = NSFont.userFixedPitchFont( ofSize: 12 )
        
        self.textView?.maxSize                            = NSSize( width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude )
        self.textView?.textContainer?.containerSize       = NSSize( width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude )
        self.textView?.textContainer?.widthTracksTextView = false
        self.textView?.isHorizontallyResizable            = true
        
        self.url = FileManager.default.urls( for: .applicationSupportDirectory, in: .userDomainMask ).first?.appendingPathComponent( "Library.json" )
        
        self.reload( nil )
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
    
    private func displayError( message: String )
    {
        let alert = NSAlert()
        
        alert.messageText     = "Error"
        alert.informativeText = message
        alert.alertStyle      = .warning
        
        alert.addButton( withTitle: "OK" )
        
        guard let window = self.window else
        {
            alert.runModal()
            
            return
        }
        
        alert.beginSheetModal( for: window, completionHandler: nil )
    }
    
    private func jsonData(  ) -> Data?
    {
        guard let data = self.textView?.string.data( using: .utf8 ) else
        {
            self.displayError( message: "Cannot save: invalid text data." )
            
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject( with: data as Data, options: [] ) else
        {
            self.displayError( message: "Cannot save: malformed JSON data." )
            
            return nil
        }
        
        if( json as? LibraryItem.LibraryType == nil )
        {
            self.displayError( message: "Cannot save: invalid JSON data." )
            
            return nil
        }
        
        return data
    }
    
    @IBAction func reload( _ sender: Any? )
    {
        guard let url = self.url else
        {
            return
        }
        
        guard let json = try? String( contentsOf: url ) else
        {
            return
        }
        
        self.textView?.string = json
    }
    
    @IBAction func saveDocument( _ sender: Any? )
    {
        guard let url = self.url else
        {
            self.displayError( message: "Cannot save: invalid URL." )
            
            return
        }
        
        guard let data = self.jsonData() else
        {
            return
        }
        
        do
        {
            try data.write( to: url, options: .atomic )
            
            guard let delegate = NSApp.delegate as? ApplicationDelegate else
            {
                return
            }
            
            delegate.mainWindowController?.libraryViewController?.reload()
        }
        catch
        {
            self.displayError( message: "Cannot save: error writing file." )
        }
    }
    
    @IBAction func saveDocumentAs( _ sender: Any? )
    {
        guard let data = self.jsonData() else
        {
            return
        }
        
        guard let window = self.window else
        {
            return
        }
        
        let panel                  = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedFileTypes     = [ "json" ]
        
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
            catch
            {
                self.displayError( message: "Cannot save: error writing file." )
            }
        }
    }
}
