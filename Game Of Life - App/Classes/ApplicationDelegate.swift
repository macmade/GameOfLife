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

@NSApplicationMain
class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    public private( set ) var mainWindowController:        MainWindowController?
    public private( set ) var aboutWindowController:       AboutWindowController?
    public private( set ) var preferencesWindowController: PreferencesWindowController?
    public private( set ) var libraryWindowController:     LibraryWindowController?
    
    func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.mainWindowController = MainWindowController()
        
        if( Preferences.shared.lastStart == nil )
        {
            self.mainWindowController?.window?.center()
        }
        
        self.mainWindowController?.window?.makeKeyAndOrderFront( nil )
        
        Preferences.shared.lastStart = Date()
        
        guard let bundled = Bundle.main.url( forResource: "Library", withExtension: "json" ) else
        {
            return
        }
        
        guard let copy = FileManager.default.urls( for: .applicationSupportDirectory, in: .userDomainMask ).first?.appendingPathComponent( "Library.json" ) else
        {
            return
        }
        
        if( FileManager.default.fileExists( atPath: copy.path ) == false )
        {
            try? FileManager.default.copyItem( at: bundled, to: copy )
        }
    }
    
    func applicationWillTerminate( _ notification: Notification )
    {}
    
    func applicationShouldTerminateAfterLastWindowClosed( _ sender: NSApplication ) -> Bool
    {
        return true
    }
    
    @IBAction func showAboutWindow( _ sender: Any? )
    {
        if( self.aboutWindowController == nil )
        {
            self.aboutWindowController = AboutWindowController()
            
            self.aboutWindowController?.window?.center()
        }
        
        self.aboutWindowController?.window?.makeKeyAndOrderFront( nil )
    }
    
    @IBAction func showPreferencesWindow( _ sender: Any? )
    {
        if( self.preferencesWindowController == nil )
        {
            self.preferencesWindowController = PreferencesWindowController()
            
            self.preferencesWindowController?.window?.center()
        }
        
        self.preferencesWindowController?.window?.makeKeyAndOrderFront( nil )
    }
    
    @IBAction func showLibraryWindow( _ sender: Any? )
    {
        if( self.libraryWindowController == nil )
        {
            self.libraryWindowController = LibraryWindowController()
            
            self.libraryWindowController?.window?.center()
        }
        
        self.libraryWindowController?.window?.makeKeyAndOrderFront( nil )
    }
}

