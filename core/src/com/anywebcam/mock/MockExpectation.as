/*
	Copyright (c) 2007, ANYwebcam.com Pty Ltd. All rights reserved.

	The software in this package is published under the terms of the BSD style 
	license, a copy of which has been included with this distribution in the 
	license.txt file.
*/
package com.anywebcam.mock
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.setTimeout;

	use namespace mock_internal;

	/**
	 * Manages expectations of method or property call(s)
	 */
	public class MockExpectation
	{
		private var _mock	:Mock;
		
		private var _failedInvocation				:Boolean;
		
		// expectation type
		private var _hasExpectationType			:Boolean;
		private var _isMethodExpectation		:Boolean;
		private var _propertyName						:String;
		                                  
		// with arguments                 
		private var _expectsArguments				:Boolean;
		private var _argumentExpectation		:ArgumentExpectation;

		// receive counts
		private var _receiveCountType				:ReceiveCountType;
		private var _expectedReceivedCount	:int;
		private var _receivedCount					:int;
		
		// return values
		private var _valuesToYield					:Array;   
		private var _errorToThrow						:Error;   

		// functions and events
		private var _funcsToInvoke					:Array // of Function
		private var _eventsToDispatch 			:Array // of EventInfo
		
		/**
		 * Constructor
		 * 
		 * @param Mock The parent Mock object this expectation is set on
		 */
		public function MockExpectation( mock:Mock )
		{
			_mock 								= mock;
			_hasExpectationType 	= false;
			_isMethodExpectation 	= false;
			_propertyName 				= '';
			_receiveCountType			= ReceiveCountType.ANY;
			_receivedCount 				= 0;
			_expectsArguments			= false;
			
			_funcsToInvoke 				= [];
			_eventsToDispatch 		= [];
		}
		
		// properties
		
		/**
		 * The name of the method or property this expectation relates to
		 */
		public function get name():String
		{
			return _propertyName;
		}

		public function set name( value:String ):void
		{
			_propertyName = value;
		}
		
		// processing //
		
		/**
		 * Check if expectation matches the property, invocation type and arguments. Called by Mock.
		 *
		 * @param propertyName
		 * @param isMethod
		 * @param args
		 */
		mock_internal function matches( propertyName:String, isMethod:Boolean, args:Array = null ):Boolean
		{
			return propertyName == _propertyName 
				&& isMethod == _isMethodExpectation 
				&& ((_argumentExpectation && _argumentExpectation.argumentsMatch( args ))
					|| (_argumentExpectation == null));
		}
		
		/**
		 * Invoke the expectation, checking its called the right way, with the correct arguments, and return any expected value
		 *
		 * @throws MockExpectationError if invoked as a method and not a method
		 * @throws MockExpectationError if invoked as a property and is a method
		 * @throws MockExpectationError if args do not match
		 */
		mock_internal function invoke( invokedAsMethod:Boolean, args:Array = null ):*
		{
			_failedInvocation = false;

			try
			{
				checkInvocationMethod( invokedAsMethod );
				checkInvocationArgs( args );

				var retval:* = doInvoke( args );
				
				return retval;
			}
			catch( e:MockExpectationError )
			{
				if( e !== _errorToThrow )
					_failedInvocation = true;
				
				throw e;
			}
			
			return null;
		}
		
		/**
		 * Check the expectation is invoked as expected, method as a method, property as a property
		 *
		 * @throws MockExpectationError if invoked as a method and not a method
		 * @throws MockExpectationError if invoked as a property and is a method
		 */
		protected function checkInvocationMethod( invokedAsMethod:Boolean ):void
		{
			if( _isMethodExpectation && ! invokedAsMethod )
				throw new MockExpectationError( 'Expectation is for a property not a method' );
			
			if( ! _isMethodExpectation && invokedAsMethod )
				throw new MockExpectationError( 'Expectation is for a method not a property' );
		}
		
		/**
		 * Check if there are expected arguments and if the supplied arguments match
		 *
		 * @throws MockExpectationError if not expecting args and was called with args
		 * @throws MockExpectationError if expecting args and was called with without args
		 * @throws MockExpectationError if args do not match
		 */
		protected function checkInvocationArgs( args:Array = null ):void
		{
			if( ! _isMethodExpectation && args != null && args.length > 1 )
				throw new MockExpectationError( 'Property expectations cannot accept multiple arguments, received:'+ args );

			if( ! _expectsArguments && args != null && args.length > 0 )
				throw new MockExpectationError( 'Not expecting arguments, received:'+ args );

			// todo: add descriptive of which arguments did not match
			if( _expectsArguments && ! _argumentExpectation.argumentsMatch( args ) )
				throw new MockExpectationError( 'Invocation arguments do not match expected arguments' );
		}
		
		/**
		 * Invoke functions, dispatch events, throw error, return values if set
		 */
		protected function doInvoke( args:Array=null ):*
		{
			// todo: handle method call order constraints

			_receivedCount++;
			
			_invokeFuncs( args );
			
			_invokeDispatchEvents( args );
			
			if( _errorToThrow != null )
			{
				throw _errorToThrow;
			}
			
			var retval:* = _invokeReturnValue();
			
			return retval;
		}
		
		/**
		 * Invoke any functions set on this expectation
		 * 
		 * @param args Any arguments supplied when calling this expectation
		 */
		protected function _invokeFuncs( args:Array = null ):void
		{
			if( _funcsToInvoke.length == 0 ) 
				return;

			_funcsToInvoke.forEach( function( func:Function, i:int, a:Array ):void 
			{ 
				func( args ); 
			});
		}
		
		/**
		 * Dispatch any evernts set on this expectation
		 * 
		 * @param args Any arguments supplied when calling this expectation		
		 */
		protected function _invokeDispatchEvents( args:Array = null ):void
		{
			if( _eventsToDispatch.length == 0 )
				return;
			
			var target:IEventDispatcher = (_mock.target as IEventDispatcher);
			
			_eventsToDispatch.forEach( function( eventInfo:EventInfo, i:int, a:Array ):void
			{
				if( eventInfo.delay <= 0 ) 
				{
					target.dispatchEvent( eventInfo.event );
				}
				else
				{
					eventInfo.timeout = setTimeout( 
						function():void { target.dispatchEvent( eventInfo.event ); }, 
						eventInfo.delay );
				}
			});
		}
		
		/**
		 * Determine and return any return value set on this expectation
		 *
		 * @return If set returns the next return value
		 */
		protected function _invokeReturnValue():*
		{
			if( _valuesToYield == null ) 
				return null;
			
			var valueIndex:int = (_receivedCount - 1) < _valuesToYield.length 
												 ? _receivedCount - 1
												 : _valuesToYield.length - 1; 
					
			return _valuesToYield[ valueIndex ];
		}
		
		// todo: rename this method
		/**
		 * Verify this expectation has had it's expectations
		 *
		 * @return True if this expecation is fulfilled, False otherwise
		 */
		public function verifyMessageReceived():Boolean
		{
			// todo: add more robust verification
			
			// if( !_hasExpectationType ) 
			// 	throw new MockExpectationError('No Expectation Set');
			
			// check if called successfully
			if( _failedInvocation )
			{
				return false;
			}
			
			if( _receiveCountType == ReceiveCountType.ANY )
			{
				return true;
			}
			
			if( _receiveCountType == ReceiveCountType.AT_LEAST && _receivedCount >= _expectedReceivedCount )
			{
				return true;
			}
			
			if( _receiveCountType == ReceiveCountType.AT_MOST && _receivedCount <= _expectedReceivedCount )
			{
				return true;
			}
			
			if( _receiveCountType == ReceiveCountType.EXACTLY && _receivedCount == _expectedReceivedCount )
			{
				return true;
			}
			
			return false;
		}
		
		/**
		 * Set the name for this expectation and whether it is for a method or a property
		 * 
		 * @param propertyName
		 * @param isMethodExpectation
		 * @return MockExpectation
		 */
		mock_internal function setExpectationType( propertyName:String, isMethodExpectation:Boolean ):MockExpectation
		{
			_hasExpectationType = true;
			_isMethodExpectation = isMethodExpectation;
			_propertyName = propertyName;
			
			return this;
		}
			
		/**
		 * Set whether arguments are expected and any constraints or literal values to expect
		 *
		 * @param areArgumentsExpected
		 * @param expectedArguments
		 * @return MockExpectation
		 */
		mock_internal function setArgumentExpectation( areArgumentsExpected:Boolean, expectedArguments:Object = null ):MockExpectation
		{
			if( _hasExpectationType && ! _isMethodExpectation 
			&& (expectedArguments is Array && (expectedArguments as Array).length > 1 ) )
				throw new MockExpectationError( 'Property expectation can only accept one argument' );

			_expectsArguments = areArgumentsExpected;
			_argumentExpectation = new ArgumentExpectation( expectedArguments );
			return this;
		}
		
		/**
		 * Set the type of and amount of calls this expectation should receive
		 *
		 * @param type
		 * @param number
		 * @return MockExpectation
		 */
		mock_internal function setReceiveCount( type:ReceiveCountType, number:int = 0 ):MockExpectation
		{
			_receiveCountType = type;
			_expectedReceivedCount = number;
			return this;
		}
		
		/**
		 * Set a single or sequence of values to return to calls of this expectation
		 *
		 * @param rest
		 * @return MockExpectation
		 */
		mock_internal function setReturnExpectation( ...rest ):MockExpectation
		{
			if( rest.length == 0 )
			{
				_valuesToYield = null;
			}
			else // if more than zero return values
			{
				// clear error to throw, otherwise return does not work
				_errorToThrow = null;
				_valuesToYield = rest;				
			}
			
			return this;
		}
		
		/**
		 * Set an error to be thrown when this expectation is called
		 *
		 * @param error
		 * @return MockExpectation
		 */
		mock_internal function setThrowExpectation( error:Error ):MockExpectation
		{
			_errorToThrow = error;
			return this;
		}
		
		/**
		 * Set a function to be invoked when this expectation is called
		 *
		 * @param func
		 * @return MockExpectation
		 */
		mock_internal function setInvokeExpectation( func:Function ):MockExpectation
		{
			_funcsToInvoke.push( func );
			return this;
		}
		
		/**
		 * Set an event to be dispatched when this expectation is called, requires the mock target to be an IEventDispatcher
		 *
		 * @param event The Event to dispatch
		 * @param delay The number of milliseconds to delay before dispatching the event
		 * @return MockExpectation
		 * @throw Error if mock target is not an IEventDispatcher
		 */
		mock_internal function setDispatchEventExpectation( event:Event, delay:Number = 0 ):MockExpectation
		{
			// fixme: is Error the best error class to throw here?
			if( !(_mock.target is IEventDispatcher) )
				throw new Error( 'Mock Target class is not an IEventDispatcher, target:', _mock.target );

			_eventsToDispatch.push( new EventInfo( event, delay ) );	
			return this;
		}
		
		/// ---- mock expectation setup ---- ///
		
		// is expectation for a method or a property?		
		
		/**
		 * Set this expectation to be a method with the supplied name
		 * 
		 * @param methodName The name of the method
		 * @return MockExpectation		
		 */
		public function method( methodName:String ):MockExpectation
		{
			return setExpectationType( methodName, true );
		}
		
		/**
		 * Set this expectation to be a property with the supplied name
		 * 
		 * @param propertyName The name of the property
		 * @return MockExpectation
		 */
		public function property( propertyName:String ):MockExpectation
		{
			return setExpectationType( propertyName, false );
		}
		
		// should it expect arguments
		
		/**
		 * Set this expectation to accept any arguments
		 */
		public function get withAnyArgs():MockExpectation
		{
			return setArgumentExpectation( true, ArgumentExpectation.ANYTHING );
		}
		
		/**
		 * Set this expectation to accept no arguments
		 */
		public function get withNoArgs():MockExpectation
		{
			return setArgumentExpectation( false, ArgumentExpectation.NO_ARGS );
		}
		
		/**
		 * Set this expectation to accept the supplied arguments or constraints
		 */
		public function withArgs( ...rest ):MockExpectation
		{
			return setArgumentExpectation( true, rest );
		}
		
		// return values
		
		/**
		 * Set a single or sequence of return values, alias of andReturn()
		 */
		public function returns( ...rest ):MockExpectation
		{
			return setReturnExpectation.apply( this, rest );
		}
		
		/**
		 * Set a single or sequence of return values, alias of returns()
		 */
		public function andReturn( ...rest ):MockExpectation
		{
			return setReturnExpectation.apply( this, rest );
		}
		
		/**
		 * Set an error to be thrown, alias of andThrow()
		 */
		public function throws( error:Error ):MockExpectation
		{
			return setReturnExpectation( error );
		}
		
		/**
		 * Set an error to be thrown, alias of throws()
		 */
		public function andThrow( error:Error ):MockExpectation
		{
			return setThrowExpectation( error );
		}
		
		/**
		 * Set the supplied function to be called when the expectation is called, alias of andCall()
		 */
		public function calls( func:Function ):MockExpectation
		{
			return setInvokeExpectation( func );
		}
		
		/**
		 * Set the supplied function to be called when the expectation is calls
		 */
		public function andCall( func:Function ):MockExpectation
		{
			return setInvokeExpectation( func );
		}
		
		/**
		 * Set the supplied event to be dispatched when the expectation is called, alias of andDispatchEvent()
		 */
		public function dispatchesEvent( event:Event, delay:Number = 0 ):MockExpectation
		{
			return setDispatchEventExpectation( event, delay );
		}
		
		/**
		 * Set the supplied event to be dispatched when the expectation is called, alias of dispatchesEvent()
		 */
		public function andDispatchEvent( event:Event, delay:Number = 0 ):MockExpectation
		{
			return setDispatchEventExpectation( event, delay );
		}
		
		// receive counts
		/**
		 * Set this expectation to expect NOT to be called
		 */
		public function get never():MockExpectation
		{
			return setReceiveCount( ReceiveCountType.EXACTLY, 0 );
		}
		
		/**
		 * Set this expectation to expect to be called ONCE only. 
		 */
		public function get once():MockExpectation
		{
			return setReceiveCount( ReceiveCountType.EXACTLY, 1 );			
		}
		
		/**
		 * Set this expectation to expect to be called TWICE only. 
		 */
		public function get twice():MockExpectation
		{
			return setReceiveCount( ReceiveCountType.EXACTLY, 2 );
		}
		
		/**
		 * Set this expectation to expect to be called exactly the supplied number of times
		 */
		public function exactly( count:int ):MockExpectation
		{
			return setReceiveCount( ReceiveCountType.EXACTLY, count );
		}
		
		/**
		 * Set this expectation to expect to be called at least the supplied number of times
		 */
		public function atLeast( count:int ):MockExpectation
		{
			return setReceiveCount( ReceiveCountType.AT_LEAST, count );
		}
		
		/**
		 * Set this expectation to expect to be called at most the supplied number of times
		 */
		public function atMost( count:int ):MockExpectation
		{
			return setReceiveCount( ReceiveCountType.AT_MOST, count );
		}
		
		/**
		 * Set this expectation to expect to be called any number of times
		 */
		public function get anyNumberOfTimes():MockExpectation
		{
			return setReceiveCount( ReceiveCountType.ANY );
		}
		
		// todo: allow a range?		
		/**
		 * Set this expectation to expect to be called the supplied number of times
		 */
		public function times( count:int = -1 ):MockExpectation
		{
			return setReceiveCount( ReceiveCountType.EXACTLY, count );
		}
		
		// method ordering
		
		/*
		public function get ordered():MockExpectation
		{
			// todo: this requires talking back up to the Mock
			
			return this;
		}
		*/
	}
}

import flash.events.Event;

/**
 * Event and delay data for the expectation
 */
internal class EventInfo
{
	public function EventInfo( event:Event, delay:Number )
	{
		this.event = event;
		this.delay = delay;
	}
	
	public function toString():String
	{
		return '[EventInfo '+ event.type +' '+ delay +']'
	}
	
	public var event:Event;
	public var delay:Number;
	public var timeout:Number;
}

/**
 * Enumeration of ReceiveCountType
 */
internal class ReceiveCountType
{
	public static const ANY				:ReceiveCountType = new ReceiveCountType('ANY');
	public static const EXACTLY		:ReceiveCountType = new ReceiveCountType('EXACTLY');
	public static const AT_LEAST	:ReceiveCountType = new ReceiveCountType('AT_LEAST');
	public static const AT_MOST		:ReceiveCountType = new ReceiveCountType('AT_MOST');
	
	public function ReceiveCountType( name:String )
	{
		_name = name;
	}
	
	public function toString():String
	{
		return _name;
	}
	
	private var _name:String;
}