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

@objc public class Preferences: NSObject
{
    @objc public dynamic var lastStart:        Date?
    @objc public dynamic var rule:             String?
    @objc public dynamic var colors:           Bool    = true
    @objc public dynamic var drawAsSquares:    Bool    = false
    @objc public dynamic var preserveGridSize: Bool    = true
    @objc public dynamic var speed:            UInt    = 10
    @objc public dynamic var cellSize:         UInt    = 10
    @objc public dynamic var drawInterval:     UInt    = 1
    
    @objc private dynamic var color1RGB: UInt = 0xFFFFFF
    @objc private dynamic var color2RGB: UInt = 0xFFFFFF
    @objc private dynamic var color3RGB: UInt = 0xFFFFFF
    @objc private dynamic var color4RGB: UInt = 0xFFFFFF
    @objc private dynamic var color5RGB: UInt = 0xFFFFFF
    @objc private dynamic var color6RGB: UInt = 0xFFFFFF
    
    @objc public static let shared = Preferences()
    
    override init()
    {
        super.init()
        
        guard let path = Bundle.main.path( forResource: "Defaults", ofType: "plist" ) else
        {
            return
        }
        
        UserDefaults.standard.register( defaults: NSDictionary( contentsOfFile: path ) as? [ String : Any ] ?? [ : ] )
        
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            self.setValue( UserDefaults.standard.object( forKey: key ), forKey: key )
            self.addObserver( self, forKeyPath: key, options: .new, context: nil )
        }
    }
    
    deinit
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            self.removeObserver( self, forKeyPath: key )
        }
    }
    
    public func activeRule() -> Rule
    {
        let name = self.rule?.uppercased() ?? ""
        
        for rule in Rule.availableRules()
        {
            if( rule.name == name )
            {
                return rule
            }
        }
        
        guard let rule = Rule( name: name, title: "Custom" ) else
        {
            return Rule.availableRules().first!
        }
        
        return rule
    }
    
    private func color( index: UInt ) -> NSColor
    {
        guard let rgb = self.value( forKey: "color" + String( index ) + "RGB" ) as! UInt? else
        {
            return NSColor.black
        }
        
        let r: CGFloat = CGFloat( ( ( rgb >> 16 ) & 0x0000FF ) ) / 255.0
        let g: CGFloat = CGFloat( ( ( rgb >>  8 ) & 0x0000FF ) ) / 255.0
        let b: CGFloat = CGFloat( ( ( rgb       ) & 0x0000FF ) ) / 255.0
        
        return NSColor( deviceRed: r, green: g, blue: b, alpha: 1 )
    }
    
    private func color( index: UInt, color: NSColor )
    {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        color.getRed( &r, green: &g, blue: &b, alpha: nil )
        
        let rgb = ( UInt( r * 255 ) << 16 ) & 0xFF0000
                | ( UInt( g * 255 ) <<  8 ) & 0x00FF00
                | ( UInt( b * 255 )       ) & 0x0000FF
        
        self.setValue( rgb, forKey: "color" + String( index ) + "RGB" )
    }
    
    public func color1() -> NSColor
    {
        return self.color( index: 1 )
    }
    
    public func color2() -> NSColor
    {
        return self.color( index: 2 )
    }
    
    public func color3() -> NSColor
    {
        return self.color( index: 3 )
    }
    
    public func color4() -> NSColor
    {
        return self.color( index: 4 )
    }
    
    public func color5() -> NSColor
    {
        return self.color( index: 5 )
    }
    
    public func color6() -> NSColor
    {
        return self.color( index: 6 )
    }
    
    public func color1( value: NSColor )
    {
        return self.color( index: 1, color: value )
    }
    
    public func color2( value: NSColor )
    {
        return self.color( index: 2, color: value )
    }
    
    public func color3( value: NSColor )
    {
        return self.color( index: 3, color: value )
    }
    
    public func color4( value: NSColor )
    {
        return self.color( index: 4, color: value )
    }
    
    public func color5( value: NSColor )
    {
        return self.color( index: 5, color: value )
    }
    
    public func color6( value: NSColor )
    {
        return self.color( index: 6, color: value )
    }
    
    @objc public override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey : Any ]?, context: UnsafeMutableRawPointer? )
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            if( key == keyPath )
            {
                UserDefaults.standard.set( change?[ NSKeyValueChangeKey.newKey ], forKey: key )
            }
        }
    }
}
