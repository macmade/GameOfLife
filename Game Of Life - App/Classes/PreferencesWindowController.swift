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

@objc class PreferencesWindowController: NSWindowController
{
    @IBOutlet private var colorsController: NSArrayController?
    
    @objc public dynamic var colors:    Bool    = Preferences.shared.colors
    @objc public dynamic var speed:     UInt    = Preferences.shared.speed
    @objc public dynamic var cellSize:  CGFloat = Preferences.shared.cellSize
    
    private var observations: [ NSKeyValueObservation ] = []
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
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
        
        self.observations.append( contentsOf: [ o1, o2, o3 ] )
        
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color1(), label: "Color 1" ) { c in Preferences.shared.color1( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color2(), label: "Color 2" ) { c in Preferences.shared.color2( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color3(), label: "Color 3" ) { c in Preferences.shared.color3( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color4(), label: "Color 4" ) { c in Preferences.shared.color4( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color5(), label: "Color 5" ) { c in Preferences.shared.color5( value: c ) } )
        self.colorsController?.addObject( PreferencesColorItem( color: Preferences.shared.color6(), label: "Color 6" ) { c in Preferences.shared.color6( value: c ) } )
    }
}
