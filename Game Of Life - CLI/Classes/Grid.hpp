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

#ifndef GOL_GRID_HPP
#define GOL_GRID_HPP

#include <cstdlib>
#include <memory>

namespace GOL
{
    class Screen;
    
    class Grid
    {
        public:
            
            enum class Type: int
            {
                Random,
                StillLife,
                Oscillators,
                Spaceships,
                GospersGuns
            };
            
            Grid( std::size_t width, std::size_t height, const Screen & screen, Type type = Type::Random );
            Grid( const Grid & o );
            Grid( Grid && o ) noexcept;
            ~Grid( void );
            
            Grid & operator =( Grid o );
            
            uint64_t population( void ) const;
            uint64_t turns( void )      const;
            
            void resize( std::size_t width, std::size_t height );
            
            bool colors( void ) const;
            void colors( bool value );
            
            void draw( std::size_t x, std::size_t y ) const;
            void next( void );
            
            friend void swap( Grid & o1, Grid & o2 );
            
        private:
            
            class IMPL;
            
            std::shared_ptr< IMPL > impl;
    };
}

#endif /* GOL_GRID_HPP */
