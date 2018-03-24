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

#include "Screen.hpp"
#include <algorithm>
#include <ncurses.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <thread>
#include <chrono>
#include <vector>
#include <mutex>
#include <condition_variable>

namespace GOL
{
    class Screen::IMPL
    {
        public:
            
            IMPL( void );
            IMPL( const IMPL & o );
            IMPL( const IMPL & o, const std::lock_guard< std::recursive_mutex > & l );
            
            void _run( void );
            void _wait( void );
            
            std::vector< std::function< void( void ) > > _updates;
            std::size_t                                  _width;
            std::size_t                                  _height;
            bool                                         _colors;
            mutable std::recursive_mutex                 _rmtx;
            std::condition_variable_any                  _cv;
            bool                                         _running;
    };
    
    Screen::Screen( void ):
        impl( std::make_shared< IMPL >() )
    {
        struct winsize s;
        
        initscr();
        
        if( has_colors() )
        {
            this->impl->_colors = true;
            
            start_color();
        }
        
        clear();
        noecho();
        cbreak();
        keypad( stdscr, true );
        refresh();
    
        ioctl( STDOUT_FILENO, TIOCGWINSZ, &s );
        
        this->impl->_width  = s.ws_col;
        this->impl->_height = s.ws_row;
    }
    
    Screen::Screen( const Screen & o ):
        impl( std::make_shared< IMPL >( *( o.impl ) ) )
    {}
    
    Screen::Screen( Screen && o ) noexcept:
        impl( std::move( o.impl ) )
    {}
    
    Screen::~Screen( void )
    {
        clrtoeol();
        refresh();
        endwin();
    }
    
    Screen & Screen::operator =( Screen o )
    {
        swap( *( this ), o );
        
        return *( this );
    }
    
    std::size_t Screen::width( void ) const
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        return this->impl->_width;
    }
    
    std::size_t Screen::height( void ) const
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        return this->impl->_height;
    }
    
    bool Screen::supportsColors( void ) const
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        return this->impl->_colors;
    }
    
    bool Screen::isRunning( void ) const
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        return this->impl->_running;
    }
    
    void Screen::update( const std::function< void( void ) > & f )
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        this->impl->_updates.push_back( f );
    }
    
    void Screen::start( void )
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        if( this->impl->_running )
        {
            return;
        }
        
        this->impl->_running = true;
        
        this->impl->_cv.notify_all();
    }
    
    void Screen::pause( void )
    {
        std::lock_guard< std::recursive_mutex > l( this->impl->_rmtx );
        
        if( this->impl->_running == false )
        {
            return;
        }
        
        this->impl->_running = false;
        
        this->impl->_cv.notify_all();
    }
    
    void swap( Screen & o1, Screen & o2 )
    {
        std::lock( o1.impl->_rmtx, o2.impl->_rmtx );
        
        {
            std::lock_guard< std::recursive_mutex > l1( o1.impl->_rmtx, std::adopt_lock );
            std::lock_guard< std::recursive_mutex > l2( o2.impl->_rmtx, std::adopt_lock );
            
            using std::swap;
            
            swap( o1.impl,  o2.impl );
        }
    }
    
    Screen::IMPL::IMPL( void ):
        _width( 0 ),
        _height( 0 ),
        _colors( false ),
        _running( false )
    {
        this->_run();
    }
    
    Screen::IMPL::IMPL( const IMPL & o ):
        IMPL( o, std::lock_guard< std::recursive_mutex >( o._rmtx ) )
    {
        this->_run();
    }
    
    Screen::IMPL::IMPL( const IMPL & o, const std::lock_guard< std::recursive_mutex > & l ):
        _width( o._width ),
        _height( o._height ),
        _colors( o._colors ),
        _running( o._running )
    {
        ( void )l;
        
        this->_run();
    }
    
    void Screen::IMPL::_run( void )
    {
        std::thread
        (
            [ this ]
            {
                while( 1 )
                {
                    this->_wait();
                    refresh();
                    
                    for( const auto & f: this->_updates )
                    {
                        refresh();
                        f();
                        refresh();
                        this->_wait();
                    }
                    
                    refresh();
                    std::this_thread::sleep_for( std::chrono::milliseconds( 10 ) );
                }
            }
        )
        .detach();
    }
    
    void Screen::IMPL::_wait( void )
    {
        std::unique_lock< std::recursive_mutex > l( this->_rmtx );
        
        this->_cv.wait
        (
            l,
            [ this ] { return this->_running; }
        );
    }
}
