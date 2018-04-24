/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
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

@objc class PreferencesWindowController: NSWindowController, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate
{
    @IBOutlet private var colorsController: NSArrayController?
    @IBOutlet private var rulesController:  NSArrayController?
    
    private var customRuleController: CustomRuleWindowController?
    
    @objc public dynamic var colors:       Bool    = Preferences.shared.colors
    @objc public dynamic var squares:      Bool    = Preferences.shared.drawAsSquares
    @objc public dynamic var preserveGrid: Bool    = Preferences.shared.preserveGridSize
    @objc public dynamic var speed:        UInt    = Preferences.shared.speed
    @objc public dynamic var cellSize:     UInt    = Preferences.shared.cellSize
    @objc public dynamic var drawInterval: UInt    = Preferences.shared.drawInterval
    @objc public dynamic var selectedRule: Any     = Preferences.shared.activeRule()
    
    private var observations: [ NSKeyValueObservation ] = []
    
    @objc private dynamic var rules: [ Any ] = []
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.window?.delegate = self
        
        var rules = [ Any ]()
        
        rules.append( "Custom..." )
        rules.append( "--" )
        
        for rule in Rule.availableRules()
        {
            rules.append( rule )
        }
        
        self.rules = rules
        
        let o1 = self.observe( \PreferencesWindowController.colors )
        {
            ( o, c ) in Preferences.shared.colors = self.colors
        }
        
        let o2 = self.observe( \PreferencesWindowController.speed )
        {
            ( o, c ) in Preferences.shared.speed = self.speed
        }
        
        let o3 = self.observe( \PreferencesWindowController.cellSize )
        {
            ( o, c ) in Preferences.shared.cellSize = self.cellSize
        }
        
        let o4 = self.observe( \PreferencesWindowController.squares )
        {
            ( o, c ) in Preferences.shared.drawAsSquares = self.squares
        }
        
        let o5 = self.observe( \PreferencesWindowController.preserveGrid )
        {
            ( o, c ) in Preferences.shared.preserveGridSize = self.preserveGrid
        }
        
        let o6 = self.observe( \PreferencesWindowController.selectedRule )
        {
            ( o, c ) in
            
            guard let rule = self.selectedRule as? Rule else
            {
                guard let s = self.selectedRule as? String else
                {
                    return
                }
                
                if( s == "Custom..." )
                {
                    let controller = CustomRuleWindowController()
                    
                    guard let window = controller.window else
                    {
                        self.selectedRule = Preferences.shared.activeRule()
                        
                        return
                    }
                    
                    self.window?.beginSheet( window )
                    {
                        ( r ) in
                        
                        if( r != .OK || self.customRuleController?.valid == false )
                        {
                            self.selectedRule = Preferences.shared.activeRule()
                            
                            return
                        }
                        
                        guard let name = self.customRuleController?.name else
                        {
                            self.selectedRule = Preferences.shared.activeRule()
                            
                            return
                        }
                        
                        Preferences.shared.rule = name
                    }
                    
                    self.customRuleController = controller
                }
                
                return
            }
            
            Preferences.shared.rule = rule.name
        }
        
        let o7 = self.observe( \PreferencesWindowController.drawInterval )
        {
            ( o, c ) in Preferences.shared.drawInterval = self.drawInterval
        }
        
        self.observations.append( contentsOf: [ o1, o2, o3, o4, o5, o6, o7 ] )
        
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color1(), label: "Color 1" ) { c in Preferences.shared.color1( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color2(), label: "Color 2" ) { c in Preferences.shared.color2( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color3(), label: "Color 3" ) { c in Preferences.shared.color3( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color4(), label: "Color 4" ) { c in Preferences.shared.color4( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color5(), label: "Color 5" ) { c in Preferences.shared.color5( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color6(), label: "Color 6" ) { c in Preferences.shared.color6( value: c ) } )
    }
    
    func windowDidBecomeKey( _ notification: Notification )
    {
        self.colors   = Preferences.shared.colors
        self.squares  = Preferences.shared.drawAsSquares
        self.speed    = Preferences.shared.speed
        self.cellSize = Preferences.shared.cellSize
    }
    
    func menuNeedsUpdate( _ menu: NSMenu )
    {
        for( i, item ) in menu.items.enumerated()
        {
            if( item.title == "--" )
            {
                menu.removeItem( at: i )
                menu.insertItem( NSMenuItem.separator(), at: i )
            }
        }
    }
}
