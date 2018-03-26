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

#ifndef GOL_OPTIONAL_HPP
#define GOL_OPTIONAL_HPP

#include <algorithm>
#include <stdexcept>
#include <functional>
#include <memory>

namespace GOL
{
    template< typename _T_ >
    class OptionalReference
    {
        public:
            
            class BadAccessException: public std::exception
            {};
            
            OptionalReference( void ):
                _hasValue( false ),
                _value( nullptr )
            {}
            
            OptionalReference( _T_ & value ):
                _hasValue( true ),
                _value( std::addressof( value ) )
            {}
            
            OptionalReference( const OptionalReference< _T_ > & o ):
                _hasValue( o._hasValue ),
                _value( o._value )
            {}
            
            OptionalReference( OptionalReference< _T_ > && o ) noexcept:
                _hasValue( std::move( o._hasValue ) ),
                _value( std::move( o._value ) )
            {}
            
            OptionalReference & operator =( OptionalReference o )
            {
                swap( *( this ), o );
                
                return ( this );
            }
            
            operator bool() const
            {
                return this->_hasValue;
            }
            
            _T_ & value( void ) const
            {
                if( this->_hasValue == false )
                {
                    throw BadAccessException();
                }
                
                return *( this->_value );
            }
            
            friend void swap( OptionalReference< _T_ > & o1, OptionalReference< _T_ > & o2 )
            {
                using std::swap;
                
                swap( o1._hasValue, o2._hasValue );
                swap( o1._value,    o2._value );
            }
            
        private:
            
            bool  _hasValue;
            _T_ * _value;
    };
}

#endif /* GOL_OPTIONAL_HPP */

