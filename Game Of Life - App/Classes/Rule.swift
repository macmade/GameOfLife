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

import Foundation

@objc public class Rule: NSObject
{
    @objc public private( set ) dynamic var name:         String
    @objc public private( set ) dynamic var title:        String
    @objc public private( set ) dynamic var displayTitle: String
    @objc public private( set ) dynamic var bornSet:      Set< Int >
    @objc public private( set ) dynamic var surviveSet:   Set< Int >
    
    static func availableRules() -> [ Rule ]
    {
        return [
            Rule( name: "B3/S23",        title: "Conway's Life" ),
            Rule( name: "B36/S23",       title: "HighLife" ),
            Rule( name: "B1357/S02468",  title: "Replicator" ),
            Rule( name: "B1357/S02468",  title: "Fredkin" ),
            Rule( name: "B2/S",          title: "Seeds" ),
            Rule( name: "B2/S0",         title: "Live Free or Die" ),
            Rule( name: "B3/S012345678", title: "Life Without Death" ),
            Rule( name: "B3/S12",        title: "Flock" ),
            Rule( name: "B3/S1234",      title: "Mazectric" ),
            Rule( name: "B3/S12345",     title: "Maze" ),
            Rule( name: "B36/S125",      title: "2x2" ),
            Rule( name: "B368/S245",     title: "Move" ),
            Rule( name: "B3678/34678",   title: "Day & Night" ),
            Rule( name: "B37/S23",       title: "DryLife" ),
            Rule( name: "B38/S23",       title: "Pedestrian Life" ),
        ]
    }
    
    init( name: String, title: String )
    {
        self.name         = name.uppercased()
        self.title        = title
        self.displayTitle = self.title + " (" + self.name + ")"
        
        let rules = name.split( separator: "/" )
        
        self.bornSet    = Set< Int >()
        self.surviveSet = Set< Int >()
        
        if
        (
               rules.count == 2
            && rules[ 0 ].count > 0
            && rules[ 1 ].count > 0
            && ( rules[ 0 ] as NSString ).substring( to: 1 ) == "B"
            && ( rules[ 1 ] as NSString ).substring( to: 1 ) == "S"
        )
        {
            let b = ( rules[ 0 ] as NSString ).substring( from: 1 )
            let s = ( rules[ 1 ] as NSString ).substring( from: 1 )
            
            for c in b
            {
                guard let i = Int( String( c ) ) else
                {
                    continue
                }
                
                self.bornSet.insert( i )
            }
            
            for c in s
            {
                guard let i = Int( String( c ) ) else
                {
                    continue
                }
                
                self.surviveSet.insert( i )
            }
        }
        
        super.init()
    }
    
    public override var description: String
    {
        return self.displayTitle
    }
}
