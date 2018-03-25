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

#include "Board.hpp"
#include "Screen.hpp"
#include "Grid.hpp"
#include <algorithm>
#include <ncurses.h>
#include <vector>
#include <cstdint>
#include <string>

namespace GOL
{
    class Board::IMPL
    {
        public:
            
            IMPL( Screen & screen );
            IMPL( const IMPL & o );
            
            void _setup( void );
            void _draw( void ) const;
            void _drawMenu( void ) const;
            
            Grid     _grid;
            Screen & _screen;
            bool     _paused;
            bool     _menu;
    };
    
    Board::Board( Screen & screen ):
        impl( std::make_shared< IMPL >( screen ) )
    {}
    
    Board::Board( const Board & o ):
        impl( std::make_shared< IMPL >( *( o.impl ) ) )
    {}
    
    Board::Board( Board && o ) noexcept:
        impl( std::move( o.impl ) )
    {}
    
    Board::~Board( void )
    {}
    
    Board & Board::operator =( Board o )
    {
        swap( *( this ), o );
        
        return *( this );
    }
    
    void swap( Board & o1, Board & o2 )
    {
        using std::swap;
        
        swap( o1.impl, o2.impl );
    }
    
    Board::IMPL::IMPL( Screen & screen ):
        _grid( screen.width(), screen.height() - 8, screen ),
        _screen( screen ),
        _paused( false )
    {
        this->_setup();
    }
    
    Board::IMPL::IMPL( const IMPL & o ):
        _grid( o._grid ),
        _screen( o._screen ),
        _paused( o._paused )
    {
        this->_setup();
    }
    
    void Board::IMPL::IMPL::_setup( void )
    {
        this->_screen.onUpdate
        (
            [ & ]( const Screen & s )
            {
                ( void )s;
                
                this->_draw();
                
                if( this->_menu == false )
                {
                    this->_grid.draw( 0, 5 );
                }
                
                if( this->_paused == false )
                {
                    this->_grid.next();
                }
            }
        );
        
        this->_screen.onResize
        (
            [ & ]( const Screen & s )
            {
                this->_grid.resize( s.width(), s.height() - 8 );
            }
        );
        
        this->_screen.onKeyPress
        (
            [ & ]( const Screen & s, int c )
            {
                bool colors( this->_grid.colors() );
                
                ( void )s;
                
                if( c == 'q' )
                {
                    exit( 0 );
                }
                
                if( c == ' ' )
                {
                    this->_paused = ( this->_paused ) ? false : true;
                }
                
                if( c == 'm' )
                {
                    this->_paused = true;
                    this->_menu   = true;
                }
                
                if( c == 'c' )
                {
                    this->_paused = false;
                    this->_menu   = false;
                }
                
                if( c == 'n' )
                {
                    this->_grid   = Grid( this->_screen.width(), this->_screen.height() - 8, this->_screen, Grid::Type::Random );
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( colors );
                }
                
                if( c == '1' )
                {
                    this->_grid   = Grid( this->_screen.width(), this->_screen.height() - 8, this->_screen, Grid::Type::StillLife );
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( colors );
                }
                
                if( c == '2' )
                {
                    this->_grid   = Grid( this->_screen.width(), this->_screen.height() - 8, this->_screen, Grid::Type::Oscillators );
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( colors );
                }
                
                if( c == '3' )
                {
                    this->_grid   = Grid( this->_screen.width(), this->_screen.height() - 8, this->_screen, Grid::Type::Spaceships );
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( colors );
                }
                
                if( c == '4' )
                {
                    this->_grid   = Grid( this->_screen.width(), this->_screen.height() - 8, this->_screen, Grid::Type::GospersGuns );
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( colors );
                }
                
                if( c == '<' )
                {
                    this->_screen.decreaseSpeed();
                }
                
                if( c == '>' )
                {
                    this->_screen.increaseSpeed();
                }
                
                if( c == 'a' )
                {
                    this->_menu   = false;
                    this->_paused = false;
                    
                    this->_grid.colors( ( this->_grid.colors() ) ? false : true );
                }
            }
        );
    }
    
    void Board::IMPL::IMPL::_draw( void ) const
    {
        std::string title(     "< Game Of Life >" );
        std::string copyright( "(c) XS-Labs 2018 - www.xs-labs.com" );
        int         y( 0 );
        
        if( this->_paused )
        {
            title += " - PAUSED";
        }
        
        ::move( y++, 0 );
        ::hline( '-', static_cast< int >( this->_screen.width() ) );
        ::move( y++, static_cast< int >( ( this->_screen.width() - title.length() ) / 2 ) );
        ::printw( title.c_str() );
        ::move( y++, 0 );
        ::hline( '-', static_cast< int >( this->_screen.width() ) );
        
        if( this->_menu )
        {
            this->_drawMenu();
        }
        else
        {
            std::string stats;
            std::string menu;
            
            stats = "Population: "
                  + std::to_string( this->_grid.population() )
                  + " | Turns: "
                  + std::to_string( this->_grid.turns() )
                  + " | Speed: "
                  + std::to_string( this->_screen.speed() );
            menu  = "[space]: pause/resume | [<]: decrease speed | [>]: increase speed | [m]: menu | [q]: quit";
            
            ::move( y, 0 );
            ::printw( stats.c_str() );
            
            ::move( y, static_cast< int >( this->_screen.width() - menu.length() ) );
            ::printw( menu.c_str() );
            
            ::move( ++y, 0 );
            ::hline( '-', static_cast< int >( this->_screen.width() ) );
        }
        
        y = static_cast< int >( this->_screen.height() - 3 );
        
        ::move( y++, 0 );
        ::hline( '-', static_cast< int >( this->_screen.width() ) );
        ::move( y++, static_cast< int >( ( this->_screen.width() - copyright.length() ) / 2 ) );
        ::printw( copyright.c_str() );
        ::move( y++, 0 );
        ::hline( '-', static_cast< int >( this->_screen.width() ) );
    }
    
    void Board::IMPL::IMPL::_drawMenu( void ) const
    {
        int y( 4 );
        std::vector< std::string > options
        {
            "    [ n ]: New random grid",
            "    [ 1 ]: Example Grid #1 - Still life",
            "    [ 2 ]: Example Grid #2 - Oscillators",
            "    [ 3 ]: Example Grid #3 - Spaceships",
            "    [ 4 ]: Example Grid #4 - Gosper's Guns",
            "    [ a ]: Toggle colors",
            "    [ c ]: Continue (exit menu)",
            "    [ q ]: Quit"
        };
        
        for( const auto & s: options )
        {
            ::move( y++, 0 );
            printw( s.c_str() );
        }
    }
}
