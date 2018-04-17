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

class LibraryItem: NSObject
{
    enum Kind
    {
        case Group
        case Item
    }
    
    @objc public dynamic var title: String
          public         var kind:  Kind
          public         var cells: [ String ]
    
    private static let Predefined: [ ( key: String, value: [ ( key: String, value: [ String ] ) ] ) ] =
    [
        (
            key: "Still Lifes",
            value:
            [
                (
                    key: "Block",
                    value:
                    [
                        "oo",
                        "oo"
                    ]
                ),
                (
                    key: "Beehive",
                    value:
                    [
                        " oo ",
                        "o  o",
                        " oo ",
                    ]
                ),
                (
                    key: "Loaf",
                    value:
                    [
                        " oo ",
                        "o  o",
                        " o o",
                        "  o ",
                    ]
                ),
                (
                    key: "Boat",
                    value:
                    [
                        "oo ",
                        "o o",
                        " o ",
                    ]
                ),
                (
                    key: "Tub",
                    value:
                    [
                        " o ",
                        "o o",
                        " o ",
                    ]
                ),
            ]
        ),
        (
            key: "Oscillators",
            value:
            [
                (
                    key: "Blinker",
                    value:
                    [
                        "ooo",
                    ]
                ),
                (
                    key: "Toad",
                    value:
                    [
                        " ooo",
                        "ooo ",
                    ]
                ),
                (
                    key: "Beacon",
                    value:
                    [
                        "oo  ",
                        "oo  ",
                        "  oo",
                        "  oo",
                    ]
                ),
                (
                    key: "Pulsar",
                    value:
                    [
                        "  ooo   ooo  ",
                        "             ",
                        "o    o o    o",
                        "o    o o    o",
                        "o    o o    o",
                        "  ooo   ooo  ",
                        "             ",
                        "  ooo   ooo  ",
                        "o    o o    o",
                        "o    o o    o",
                        "o    o o    o",
                        "             ",
                        "  ooo   ooo  ",
                    ]
                ),
                (
                    key: "Pentadecathlon",
                    value:
                    [
                        "ooo",
                        "o o",
                        "ooo",
                        "ooo",
                        "ooo",
                        "ooo",
                        "o o",
                        "ooo",
                    ]
                ),
            ]
        ),
        (
            key: "Spaceships",
            value:
            [
                (
                    key: "Glider",
                    value:
                    [
                        " o ",
                        "  o",
                        "ooo"
                    ]
                ),
                (
                    key: "LWSS",
                    value:
                    [
                        " ooooo",
                        "o    o",
                        "     o",
                        "o   o "
                    ]
                ),
            ]
        )
    ]
    
    init( title: String = "" )
    {
        self.title = title
        self.kind  = .Group
        self.cells = [ String ]()
        
        super.init()
    }
    
    init( title: String = "", cells: [ String ] )
    {
        self.title = title
        self.kind  = .Item
        self.cells = cells
        
        super.init()
    }
    
    public static func allItems() -> [ LibraryItem ]
    {
        var items = [ LibraryItem ]()
        
        for p1 in Predefined
        {
            items.append( LibraryItem( title: p1.key ) )
            
            for p2 in p1.value
            {
                items.append( LibraryItem( title: p2.key, cells: p2.value ) )
            }
        }
        
        return items
    }
}
