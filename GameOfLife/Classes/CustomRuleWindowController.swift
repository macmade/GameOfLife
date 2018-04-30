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

@objc class CustomRuleWindowController: NSWindowController
{
    @objc public private( set ) dynamic var valid = false
    @objc public private( set ) dynamic var name  = ""
    
    public private( set ) var bornSet    = Set< Int >()
    public private( set ) var surviveSet = Set< Int >()
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {}
    
    @IBAction func help( _ sender: Any? )
    {
        guard let url = URL( string: "http://www.conwaylife.com/wiki/Rules" ) else
        {
            return
        }
        
        NSWorkspace.shared.open( url )
    }
    
    @IBAction func cancel( _ sender: Any? )
    {
        guard let window = self.window else
        {
            return
        }
        
        self.window?.sheetParent?.endSheet( window, returnCode: .cancel )
    }
    
    @IBAction func ok( _ sender: Any? )
    {
        guard let window = self.window else
        {
            return
        }
        
        self.window?.sheetParent?.endSheet( window, returnCode: .OK )
    }
    
    @IBAction func ruleChanged( _ sender: Any? )
    {
        guard let segment = sender as? NSSegmentedControl else
        {
            return
        }
        
        guard let id = segment.identifier else
        {
            return
        }
        
        if( id == NSUserInterfaceItemIdentifier( "B" ) )
        {
            self.bornSet.removeAll()
            
            for i in 0 ..< segment.segmentCount
            {
                if( segment.isSelected( forSegment: i ) )
                {
                    self.bornSet.insert( i )
                }
            }
        }
        else if( id == NSUserInterfaceItemIdentifier( "S" ) )
        {
            self.surviveSet.removeAll()
            
            for i in 0 ..< segment.segmentCount
            {
                if( segment.isSelected( forSegment: i ) )
                {
                    self.surviveSet.insert( i )
                }
            }
        }
        
        if( self.bornSet.count > 0 && self.surviveSet.count > 0 )
        {
            var b = "B"
            var s = "S"
            
            for i in self.bornSet.sorted()
            {
                b += String( describing: i )
            }
            
            for i in self.surviveSet.sorted()
            {
                s += String( describing: i )
            }
            
            self.name  = b + "/" + s
            self.valid = true
        }
        else
        {
            self.valid = false
            self.name  = ""
        }
    }
}
