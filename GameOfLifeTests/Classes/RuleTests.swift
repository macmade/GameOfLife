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
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 ******************************************************************************/

import Testing
@testable import GOL

/// Tests for `Rule` B/S string parsing and the predefined rule list.
@Suite( "Rule parsing & predefined rules" )
struct RuleTests
{
    /// A valid `B/S` string produces the expected born and survive sets.
    @Test( "Valid B/S string parses into the right born/survive sets" )
    func validRuleParses() throws
    {
        let rule = try #require( Rule( name: "B3/S23", title: "Conway's Life" ) )

        #expect( rule.bornSet    == [ 3 ] )
        #expect( rule.surviveSet == [ 2, 3 ] )
    }

    /// Multi-digit born/survive specifications are parsed digit by digit.
    @Test( "Multi-digit born/survive specifications parse fully" )
    func multiDigitRuleParses() throws
    {
        let rule = try #require( Rule( name: "B3678/S34678", title: "Day & Night" ) )

        #expect( rule.bornSet    == [ 3, 6, 7, 8 ] )
        #expect( rule.surviveSet == [ 3, 4, 6, 7, 8 ] )
    }

    /// `displayTitle` combines the title and the (uppercased) rule name.
    @Test( "displayTitle and name are formed correctly" )
    func displayTitleIsFormed() throws
    {
        let rule = try #require( Rule( name: "B3/S23", title: "Conway's Life" ) )

        #expect( rule.name         == "B3/S23" )
        #expect( rule.title        == "Conway's Life" )
        #expect( rule.displayTitle == "Conway's Life (B3/S23)" )
    }

    /// A rule created through the public initializer is not flagged predefined.
    @Test( "Rules built via the public initializer are not predefined" )
    func publicInitializerIsNotPredefined() throws
    {
        let rule = try #require( Rule( name: "B3/S23", title: "Custom" ) )

        #expect( rule.predefined == false )
    }

    /// Structurally malformed rule strings fail the failable initializer.
    @Test( "Malformed rule strings fail the initializer", arguments: [
        "",          // empty
        "B3",        // no separator
        "B3/S2/3",   // too many components
        "X3/S23",    // missing B prefix
        "B3/X23",    // missing S prefix
    ] )
    func malformedRulesFail( _ name: String )
    {
        #expect( Rule( name: name, title: "Bad" ) == nil )
    }

    /// The predefined list is non-empty, all flagged predefined, with unique names.
    @Test( "Predefined rule list is complete and consistent" )
    func predefinedRulesAreConsistent()
    {
        let rules = Rule.availableRules()
        let names = rules.map { $0.name }

        #expect( rules.count == 15 )
        #expect( rules.allSatisfy { $0.predefined } )
        #expect( Set( names ).count == names.count )
    }

    /// Spot-check a few predefined rules' born/survive sets.
    @Test( "Predefined rules carry the expected born/survive sets" )
    func predefinedRulesHaveExpectedSets() throws
    {
        let byName = Dictionary( uniqueKeysWithValues: Rule.availableRules().map { ( $0.name, $0 ) } )

        let conway   = try #require( byName[ "B3/S23" ] )
        let seeds    = try #require( byName[ "B2/S" ] )
        let highLife = try #require( byName[ "B36/S23" ] )

        #expect( conway.bornSet      == [ 3 ] )
        #expect( conway.surviveSet   == [ 2, 3 ] )
        #expect( seeds.bornSet       == [ 2 ] )
        #expect( seeds.surviveSet    == [] )
        #expect( highLife.bornSet    == [ 3, 6 ] )
        #expect( highLife.surviveSet == [ 2, 3 ] )
    }
}
