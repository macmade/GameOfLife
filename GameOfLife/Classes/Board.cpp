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
#include "Cell.hpp"
#include "OptionalReference.hpp"
#include <algorithm>
#include <ncurses.h>
#include <vector>
#include <cstdint>
#include <mutex>

namespace GOL
{
    class Board::IMPL
    {
        public:
            
            IMPL( Screen & screen );
            IMPL( const IMPL & o );
            IMPL( const IMPL & o, const std::lock_guard< std::recursive_mutex > & l );
            
            OptionalReference< Cell >                     _cellAt( std::size_t x, std::size_t y );
            std::vector< std::reference_wrapper< Cell > > _adjacentCells( std::size_t x, std::size_t y );
            std::size_t                                   _numberOfAdjacentLivingCells( std::size_t x, std::size_t y );
            
            Screen                           & _screen;
            std::size_t                        _width;
            std::size_t                        _height;
            std::vector< std::vector< Cell > > _cells;
            mutable std::recursive_mutex       _rmtx;
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
    
    void Board::draw( void ) const
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        if( this->impl->_screen.supportsColors() )
        {
            init_pair( 1, COLOR_WHITE, COLOR_RED );
            init_pair( 2, COLOR_WHITE, COLOR_YELLOW );
            init_pair( 3, COLOR_WHITE, COLOR_GREEN );
            init_pair( 4, COLOR_WHITE, COLOR_CYAN );
            init_pair( 5, COLOR_WHITE, COLOR_BLUE );
            init_pair( 6, COLOR_WHITE, COLOR_MAGENTA );
        }
        
        for( std::size_t i = 0; i < this->impl->_height; i++ )
        {
            for( std::size_t j = 0; j < this->impl->_width; j++ )
            {
                OptionalReference< Cell > cell( this->impl->_cellAt( j, i ) );
                
                if( cell == false )
                {
                    continue;
                }
                
                if( this->impl->_screen.supportsColors() )
                {
                    attron( COLOR_PAIR( ( cell.value().age() <= 6 ) ? cell.value().age() : 6 ) );
                }
                
                if( cell.value().isAlive() )
                {
                    if( this->impl->_screen.supportsColors() )
                    {
                       mvaddch( i, j, 32 );
                    }
                    else
                    {
                       mvaddch( i, j, '.' );
                    }
                }
                else
                {
                    mvaddch( i, j, 10 );
                }
            }
        }
    }
    
    void Board::next( void )
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        auto                                    cells( this->impl->_cells );
        
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
    
    void swap( Board & o1, Board & o2 )
    {
        std::lock( o1.impl->_rmtx, o2.impl->_rmtx );
        
        {
            std::lock_guard< std::recursive_mutex > l1( o1.impl->_rmtx, std::adopt_lock );
            std::lock_guard< std::recursive_mutex > l2( o2.impl->_rmtx, std::adopt_lock );
            
            using std::swap;
            
            swap( o1.impl, o2.impl );
        }
    }
    
    Board::IMPL::IMPL( Screen & screen ):
        _screen( screen ),
        _width( 0 ),
        _height( 0 )
    {
        this->_width  = 50;
        this->_height = 50;
        
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
    
    Board::IMPL::IMPL( const IMPL & o ):
        IMPL( o, std::lock_guard< std::recursive_mutex >( o._rmtx ) )
    {}
    
    Board::IMPL::IMPL( const IMPL & o, const std::lock_guard< std::recursive_mutex > & l ):
        _screen( o._screen ),
        _width( o._width ),
        _height( o._height ),
        _cells( o._cells )
    {
        ( void )l;
    }
    
    OptionalReference< Cell > Board::IMPL::_cellAt( std::size_t x, std::size_t y )
    {
        std::lock_guard< std::recursive_mutex > l( this->_rmtx );
        
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
    
    std::vector< std::reference_wrapper< Cell > > Board::IMPL::_adjacentCells( std::size_t x, std::size_t y )
    {
        std::lock_guard< std::recursive_mutex >       l( this->_rmtx );
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
    
    std::size_t Board::IMPL::_numberOfAdjacentLivingCells( std::size_t x, std::size_t y )
    {
        std::lock_guard< std::recursive_mutex > l( this->_rmtx );
        std::size_t                             n( 0 );
        
        for( const auto & cell: this->_adjacentCells( x, y ) )
        {
            n += ( cell.get().isAlive() ) ? 1 : 0;
        }
        
        return n;
    }
}
