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

#include "Grid.hpp"
#include "Screen.hpp"
#include "Cell.hpp"
#include "OptionalReference.hpp"
#include <algorithm>
#include <ncurses.h>
#include <vector>
#include <cstdint>

namespace GOL
{
    class Grid::IMPL
    {
        public:
            
            IMPL( std::size_t width, std::size_t height, const Screen & screen );
            IMPL( const IMPL & o );
            
            OptionalReference< Cell >                     _cellAt( std::size_t x, std::size_t y );
            std::vector< std::reference_wrapper< Cell > > _adjacentCells( std::size_t x, std::size_t y );
            std::size_t                                   _numberOfAdjacentLivingCells( std::size_t x, std::size_t y );
            std::size_t                                   _numberOfLivingCells( void );
            
            const Screen                     & _screen;
            std::size_t                        _width;
            std::size_t                        _height;
            uint64_t                           _turns;
            std::vector< std::vector< Cell > > _cells;
    };
    
    Grid::Grid( std::size_t width, std::size_t height, const Screen & screen ):
        impl( std::make_shared< IMPL >( width, height, screen ) )
    {}
    
    Grid::Grid( const Grid & o ):
        impl( std::make_shared< IMPL >( *( o.impl ) ) )
    {}
    
    Grid::Grid( Grid && o ) noexcept:
        impl( std::move( o.impl ) )
    {}
    
    Grid::~Grid( void )
    {}
    
    Grid & Grid::operator =( Grid o )
    {
        swap( *( this ), o );
        
        return *( this );
    }
    
    uint64_t Grid::population( void ) const
    {
        uint64_t n( 0 );
        
        for( const auto & row: this->impl->_cells )
        {
            for( const auto & cell: row )
            {
                n += ( cell.isAlive() ) ? 1 : 0;
            }
        }
        
        return n;
    }
    
    uint64_t Grid::turns( void ) const
    {
        return this->impl->_turns;
    }
    
    void Grid::draw( std::size_t x, std::size_t y ) const
    {
        if( this->impl->_screen.supportsColors() )
        {
            ::init_pair( 1, COLOR_RED,     COLOR_RED );
            ::init_pair( 2, COLOR_YELLOW,  COLOR_YELLOW );
            ::init_pair( 3, COLOR_GREEN,   COLOR_GREEN );
            ::init_pair( 4, COLOR_CYAN,    COLOR_CYAN );
            ::init_pair( 5, COLOR_BLUE,    COLOR_BLUE );
            ::init_pair( 6, COLOR_MAGENTA, COLOR_MAGENTA );
        }
        
        for( std::size_t i = 0; i < this->impl->_height; i++ )
        {
            for( std::size_t j = 0; j < this->impl->_width; j++ )
            {
                OptionalReference< Cell > cell( this->impl->_cellAt( j, i ) );
                unsigned long long        attr( COLOR_PAIR( ( cell.value().age() <= 6 ) ? cell.value().age() : 6 ) );
                
                if( cell == false )
                {
                    continue;
                }
                
                ::move( static_cast< int >( i + y ), static_cast< int >( j + x ) );
                
                if( cell.value().isAlive() )
                {
                    if( this->impl->_screen.supportsColors() )
                    {
                        ::attron( attr );
                    }
                    
                    ::printw( "o" );
                    
                    if( this->impl->_screen.supportsColors() )
                    {
                        ::attroff( attr );
                    }
                }
                else
                {
                    if( this->impl->_screen.supportsColors() )
                    {
                        ::attroff( COLOR_PAIR( 1 ) );
                        ::attroff( COLOR_PAIR( 2 ) );
                        ::attroff( COLOR_PAIR( 3 ) );
                        ::attroff( COLOR_PAIR( 4 ) );
                        ::attroff( COLOR_PAIR( 5 ) );
                        ::attroff( COLOR_PAIR( 6 ) );
                    }
                    
                    ::printw( " " );
                }
            }
        }
    }
    
    void Grid::next( void )
    {
        auto cells( this->impl->_cells );
        
        if( this->impl->_turns < UINT64_MAX )
        {
            this->impl->_turns++;
        }
        
        for( std::size_t i = 0; i < cells.size(); i++ )
        {
            for( std::size_t j = 0; j < cells[ i ].size(); j++ )
            {
                Cell &      cell( cells[ i ][ j ] );
                bool        alive( cell.isAlive() );
                std::size_t count( this->impl->_numberOfAdjacentLivingCells( j, i ) );
                
                if( alive && count < 2 )
                {
                    cell.isAlive( false );
                }
                else if( alive && count > 3 )
                {
                    cell.isAlive( false );
                }
                else if( alive == false && count == 3 )
                {
                    cell.isAlive( true );
                }
                
                if( alive && cell.isAlive() && cell.age() < UINT64_MAX )
                {
                    cell.age( cell.age() + 1 );
                }
            }
        }
        
        this->impl->_cells = cells;
    }
    
    void swap( Grid & o1, Grid & o2 )
    {
        using std::swap;
        
        swap( o1.impl, o2.impl );
    }
    
    Grid::IMPL::IMPL( std::size_t width, std::size_t height, const Screen & screen ):
        _screen( screen ),
        _width( width ),
        _height( height ),
        _turns( 0 )
    {
        this->_cells.resize( this->_height );
        
        for( std::size_t i = 0; i < this->_height; i++ )
        {
            this->_cells[ i ].resize( this->_width );
        }
        
        for( auto & row: this->_cells )
        {
            for( auto & cell: row )
            {
                cell.isAlive( arc4random() % 3 == 1 );
            }
        }
    }
    
    Grid::IMPL::IMPL( const IMPL & o ):
        _screen( o._screen ),
        _width( o._width ),
        _height( o._height ),
        _cells( o._cells ),
        _turns( o._turns )
    {}
    
    OptionalReference< Cell > Grid::IMPL::_cellAt( std::size_t x, std::size_t y )
    {
        if( y >= this->_cells.size() )
        {
            return {};
        }
        
        if( x >= this->_cells[ y ].size() )
        {
            return {};
        }
        
        return this->_cells[ y ][ x ];
    }
    
    std::vector< std::reference_wrapper< Cell > > Grid::IMPL::_adjacentCells( std::size_t x, std::size_t y )
    {
        std::vector< std::reference_wrapper< Cell > > ret;
        std::vector< OptionalReference< Cell > >      cells
        {
            this->_cellAt( x - 1, y - 1 ),
            this->_cellAt( x,     y - 1 ),
            this->_cellAt( x + 1, y - 1 ),
            this->_cellAt( x - 1, y ),
            this->_cellAt( x + 1, y ),
            this->_cellAt( x - 1, y + 1 ),
            this->_cellAt( x,     y + 1 ),
            this->_cellAt( x + 1, y + 1 ),
        };
        
        for( const auto & cell: cells )
        {
            if( cell )
            {
                ret.push_back( cell.value() );
            }
        }
        
        return ret;
    }
    
    std::size_t Grid::IMPL::_numberOfAdjacentLivingCells( std::size_t x, std::size_t y )
    {
        std::size_t n( 0 );
        
        for( const auto & cell: this->_adjacentCells( x, y ) )
        {
            n += ( cell.get().isAlive() ) ? 1 : 0;
        }
        
        return n;
    }
    
    std::size_t Grid::IMPL::_numberOfLivingCells( void )
    {
        std::size_t n( 0 );
        
        for( const auto & row: this->_cells )
        {
            for( const auto & cell: row )
            {
                n += ( cell.isAlive() ) ? 1 : 0;
            }
        }
        
        return n;
    }
}
