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

#include "Cell.hpp"
#include <algorithm>

namespace GOL
{
    Cell::Cell( void ):
        _alive( false ),
        _age( 0 )
    {}
    
    Cell::Cell( const Cell & o ):
        _alive( o._alive ),
        _age( o._age )
    {}
    
    Cell::Cell( Cell && o ) noexcept:
        _alive( o._alive ),
        _age( o._age )
    {}
    
    Cell::~Cell( void )
    {}
    
    Cell & Cell::operator =( Cell o )
    {
        swap( *( this ), o );
        
        return *( this );
    }
    
    bool Cell::isAlive( void ) const
    {
        return this->_alive;
    }
    
    void Cell::isAlive( bool value )
    {
        if( value == false )
        {
            this->_age = 0;
        }
        
        this->_alive = value;
    }
    
    uint64_t Cell::age( void ) const
    {
        return this->_age;
    }
    
    void Cell::age( uint64_t value )
    {
        this->_age = value;
    }
    
    void swap( Cell & o1, Cell & o2 )
    {
        using std::swap;
        
        swap( o1._alive, o2._alive );
        swap( o1._age,   o2._age );
    }
}

