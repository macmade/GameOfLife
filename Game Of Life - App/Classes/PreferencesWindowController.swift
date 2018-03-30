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
    @objc private dynamic var color1:       NSColor                   = NSColor.black
    @objc private dynamic var color2:       NSColor                   = NSColor.black
    @objc private dynamic var color3:       NSColor                   = NSColor.black
    @objc private dynamic var color4:       NSColor                   = NSColor.black
    @objc private dynamic var color5:       NSColor                   = NSColor.black
    @objc private dynamic var color6:       NSColor                   = NSColor.black
    @objc private dynamic var observations: [ NSKeyValueObservation ] = []
    
    override var windowNibName: String?
    {
        return NSStringFromClass( type( of: self ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.color1 = Preferences.shared.color1()
        self.color2 = Preferences.shared.color2()
        self.color3 = Preferences.shared.color3()
        self.color4 = Preferences.shared.color4()
        self.color5 = Preferences.shared.color5()
        self.color6 = Preferences.shared.color6()
        
        let o1 = self.observe( \.color1 )
        {
            ( o, c ) in Preferences.shared.color1( value: self.color1 )
        }
        
        let o2 = self.observe( \.color2 )
        {
            ( o, c ) in Preferences.shared.color1( value: self.color1 )
        }
        
        let o3 = self.observe( \.color3 )
        {
            ( o, c ) in Preferences.shared.color2( value: self.color2 )
        }
        
        let o4 = self.observe( \.color4 )
        {
            ( o, c ) in Preferences.shared.color3( value: self.color3 )
        }
        
        let o5 = self.observe( \.color5 )
        {
            ( o, c ) in Preferences.shared.color4( value: self.color4 )
        }
        
        let o6 = self.observe( \.color6 )
        {
            ( o, c ) in Preferences.shared.color5( value: self.color5 )
        }
        
        self.observations.append( contentsOf: [ o1, o2, o3, o4, o5, o6 ] )
    }
}
