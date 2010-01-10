/*
	Copyright (c) 2007, ANYwebcam.com Pty Ltd. All rights reserved.

	The software in this package is published under the terms of the BSD style 
	license, a copy of which has been included with this distribution in the 
	license.txt file.
*/
package com.anywebcam.mock
{
	import com.anywebcam.mock.*;
	
	use namespace mock_internal;

	import flash.events.*;
	import flexunit.framework.TestCase;
	import flexunit.framework.TestSuite;

	public class MockExpectationTest extends TestCase
	{
		public static function suite():TestSuite
		{
			return new TestSuite( MockExpectationTest );
		}
		
		public function MockExpectationTest( method:String = null )
		{
			super( method );
		}
		
		public var mock	:Mock;
		public var e :MockExpectation;
		
		override public function setUp():void
		{
			mock = new Mock( new EventDispatcher() );
			e = new MockExpectation( mock );
		}
		
		override public function tearDown():void
		{
			mock = null;
			e = null;
		}
		
		// setting method expectations
		public function testShouldSetMethodExpectation():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true);
			
			e.method('testMethod').once;
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testMethodExpectationShouldOverridePropertyExpectationIfSetAfterwards():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true);
			
			e.property('donuts');
			e.method('testMethod').once;
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testMethodExpectationShouldFailIfCalledAsProperty():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', false);
			
			try
			{
				e.method('testMethod').once;
				e.invoke( invocation );
				fail( 'Expecting invoking the MockExpectation as property to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}
		
		// method arguments
		public function testMethodExpectationShouldAcceptNoArgumentsAndVerifyIfInvokedWithNoArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true);
			
			e.method('testMethod').withNoArgs;
			e.invoke( invocation );
			assertTrue( e.verify() );
		}

		public function testMethodExpectationShouldAcceptNoArgumentsAndFailVerifyIfInvokedWithArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, [1, 2, 3]);
			
			try
			{
				e.method('testMethod').once.withNoArgs;
				e.invoke( invocation );
				
				fail( 'Expecting invocation with arguments to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}

		public function testMethodExpectationShouldVerifyWithNoArgsWhenSetToAcceptAnyArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true);
			
			e.method('testMethod').withAnyArgs;
			
			e.invoke( invocation );
			assertTrue( e.verify() );
		}

		public function testMethodExpectationShouldVerifyWithNullWhenSetToAcceptAnyArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, null);
			
			e.method('testMethod').withAnyArgs;
			
			e.invoke( invocation );
			assertTrue( e.verify() );						
		}

		public function testMethodExpectationShouldVerifyWithAnyArgsWhenSetToAcceptAnyArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, [1, 2, 3, 4]);
			
			e.method('testMethod').withAnyArgs;
						
			e.invoke( invocation );
			assertTrue( e.verify() );			
		}
		
		public function testMethodExpectationShouldAcceptSpecificArgumentsAndVerityIfInvokeWithCorrectArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, [1, true, 'test']);
			
			e.method('testMethod').withArgs( Number, Boolean, String );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testMethodExpectationShouldAcceptSpecificArgumentsAndFailVerifyIfInvokedWithIncorrectArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, ['toast', 'crumpets', false]);
			
			try
			{
				e.method('testMethod').withArgs( Number, Boolean, String );
				e.invoke( invocation );
				fail( 'Expecting invocation with incorrect arguments to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}
		
		public function testMethodExpectationShouldAcceptSingleLiteralValue():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, [1]);
			
			e.method('icanhasone').withArgs( 1 );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testMethodExpectationShouldAcceptSingleLiteralValueAndFailVerifyIfInvokedWithIncorrectArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testMethod', true, [0]);
			
			try
			{
				e.method('icanhasone').withArgs( 1 );
				e.invoke(invocation);
				fail( 'Expecting invocation with incorrect arguments to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}
		
		// setting property expectations
		public function testShouldSetPropertyExpectation():void
		{
			var invocation : MockInvocation = new MockInvocation('testProperty', false);
			
			e.property('testProperty');
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testPropertyExpectationShouldOverrideMethodExpectationIfSetAfterwards():void
		{
			var invocation : MockInvocation = new MockInvocation('donuts', false);
			
			e.method('toast');
			e.property('donuts');
			assertEquals( 'donuts', e.name );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testPropertyExpectationShouldVerifyWithCorrectArgument():void
		{
			var invocation : MockInvocation = new MockInvocation('testProperty', false, ['hello']);
			
			e.property('testProperty').withArgs( String );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testPropertyExpectationShouldFailToVerifyWithIncorrectArgument():void
		{
			var invocation : MockInvocation = new MockInvocation('testProperty', false, [4]);
			
			try
			{
				e.property('testProperty').withArgs( String );
				e.invoke( invocation );
				fail( 'Expecting invocation with incorrect arguments to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}
		
		public function testPropertyExpectationShouldComplainOnSettingMoreThanOneArgumentExpectation():void
		{
			try
			{
				e.property('testProperty').withArgs( String, Number );
				fail( 'Expecting settings multiple argument expectations to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				// true because we didnt invoke the property, and the default receive count is any
				assertTrue( e.verify() );
			}
		}
		
		public function testPropertyExpectationShouldFailToVerifyIfInvokedWithMultipleArguments():void
		{
			var invocation : MockInvocation = new MockInvocation('testProperty', false, ['hello', 'world']);
			
			try
			{
				e.property('testProperty').withArgs( String );
				e.invoke( invocation );
				fail( 'Expecting invocation of property with multiple arguments to throw an error' );
			}
			catch( error:MockExpectationError )
			{
				try { e.verify(); fail('Expecting MockExpectationError'); } 
				catch (error:MockExpectationError) { ;/* NOOP */ }
			}
		}
		
		// settings return values
		public function testShouldSetReturnValuesOverridesPreviouslySetThrowError():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').andThrow( new Error('NotToBeThrown') ).andReturn( true );
			var retval:* = e.invoke( invocation );
			assertEquals( true, retval );
		}
		
		public function testShouldSetReturnValueAndReturnItOnInvoke():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').andReturn( true );
			var retval:* = e.invoke( invocation );
			assertEquals( true, retval );
		}
		
		public function testShouldSetMulitpleReturnValuesAndReturnValuesInSetSequence():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').andReturn( 1, 1, 2, 3, 5, 8 );

			var expectedValues:Array = [1, 1, 2, 3, 5, 8 ];
			expectedValues.forEach( function( v:Number, i:int, a:Array ):void
			{
				assertTrue( v, e.invoke( invocation ) );
			});
			
			assertTrue( e.verify() );
		}
		
		public function testShouldReturnValuesSequentiallyThenRepeatLastValueForAllSubsequentInvocations():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').andReturn( 'the good', 'the bad', 'the ugly' );

			var expectedValues:Array = [ 'the good', 'the bad', 'the ugly', 'the ugly', 'the ugly' ];
			expectedValues.forEach( function( v:String, i:int, a:Array ):void
			{
				assertEquals( v, e.invoke( invocation ) );
			});
			
			assertTrue( e.verify() );
		}
		
		// settings throw errors
		public function testShouldSetThrowErrorOverridesPreviouslySetReturnValues():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			try
			{
				e.method('test').andReturn( 'dontReturnMe' ).andThrow( new Error('PleaseThrowMe') );
				e.invoke( invocation );
				fail( 'Expecting the set throw error to be thrown' );
			}
			catch( error:Error )
			{
				assertEquals( 'PleaseThrowMe', error.message );
			}
		}
		
		public function testShouldSetThrowErrorAndThrowErrorOnInvokeAndVerify():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			try
			{
				e.method('test').andThrow( new Error('ThrownByMockExpectation') );
				e.invoke( invocation );
				fail( 'Expecting set error to be thrown on expectation invocation' );
			}
			catch( error:Error )
			{
				assertEquals( 'ThrownByMockExpectation', error.message );
				assertTrue( e.verify() );
			}
		}
		
		// setting receive counts
		public function testShouldVerifyIfReceiveCountIsAnyAndExpectationIsNotInvoked():void
		{
			e.method('test').anyNumberOfTimes;
			assertTrue( e.verify() );
		}
		
		public function testShouldVerifyIfReceiveCountIsAnyAndExpectationIsInvoked():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').anyNumberOfTimes;
			e.invoke( invocation );
			e.invoke( invocation );
			e.invoke( invocation );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testShouldVerifyIfReceiveCountIsNeverAndExpectationIsNotInvoked():void
		{
			e.method('test').never;
			assertTrue( e.verify() );
		}
		
		public function testShouldNotVerifyIfReceiveCountIsNeverAndExpectationIsInvoked():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').never;
			
			try
			{
				e.invoke( invocation );
				fail('Expecting MockExpectation#invoke to throw a MockExpectationError');
			}
			catch( error:MockExpectationError )
			{
				; // NOOP
			}
		}
		
		// invoke exactly
		public function testShouldVerifyIfReceiveCountIsExactlyAndInvokedCorrectNumberOfTimes():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').exactly( 3 );
			e.invoke( invocation );
			e.invoke( invocation );
			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		public function testShouldNotVerifyIfReceiveCountIsExactlyAndNotInvokedCorrectNumberOfTimes():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').exactly( 1 );
			e.invoke( invocation );
			e.invoke( invocation );
			e.invoke( invocation );
			try 
			{
				e.verify();
				fail('Expecting MockExpectation#verifyMessageReceived to throw a MockExpectationError');
			}
			catch( error:MockExpectationError ) 
			{
				; // NOOP
			}
		}
		
		// invoked less than, and more than
		public function testShouldVerifyIfReceiveCountIsAtLeast():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').atLeast( 3 );
			
			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }
			
			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }
			
			e.invoke( invocation );
			assertTrue( e.verify() );

			e.invoke( invocation );
			assertTrue( e.verify() );
		}
		
		// invoked less than, and more than
		public function testShouldVerifyIfReceiveCountIsAtMost():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').atMost( 2 );
			
			e.invoke( invocation );
			assertTrue( e.verify() );
			
			e.invoke( invocation );
			assertTrue( e.verify() );
			
			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }

			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }
		}
		
		// at least, at most, at least & at most
		public function testShouldVerifyIfReceiveCountIsAtLeastAndAtMost():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').atLeast( 2 ).atMost( 3 );
			
			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }

			e.invoke( invocation );
			assertTrue( e.verify() );

			e.invoke( invocation );
			assertTrue( e.verify() );

			e.invoke( invocation );
			try { e.verify(); fail('Expecting MockExpectationError'); } 
			catch (error:MockExpectationError) { ;/* NOOP */ }
		}
		
		// receive counts only apply to matching args
		public function testReceiveCountShouldOnlyApplyToMatchingArguments():void
		{
			mock.method('hi').withArgs(1).once;
			mock.method('hi').withArgs(2).twice;
			mock.method('hi').withArgs(3);
			mock.hi(1);
			mock.hi(2);
			mock.hi(2);
			for( var i:int=0, n:int=20; i < n; i++ )
			{
				mock.hi(3);
			}
			assertTrue( mock.verify() );
		}
		
		public function testReceiveCountShouldNotApplyToMismatchedArguments():void
		{
			mock.method('hi').withArgs(1).once;
			mock.method('hi').withArgs(2).twice;
			mock.method('hi').withArgs(3);
			mock.method('lo');
			
			mock.hi(1);
			mock.hi(2);
			mock.lo();
			for( var i:int=0, n:int=20; i < n; i++ )
			{
				mock.hi(3);
			}
			
			try 
			{
				mock.verify();
				fail('Expecting MockExpectationError for receiveCount not met for mock.method("hi").withArgs(2).twice');
			}
			catch (error:MockExpectationError) 
			{
				; // NOOP
			}
		}
		
		// invoking functions
		public function testShouldSetFunctionToInvokeOnInvokingExpectation():void
		{
			var invoked:int = 0;
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test').andCall( function():void { invoked++; });
			e.invoke( invocation );
			
			assertEquals( 1, invoked );
		}
		
		public function testShouldSetMultipleFunctionsToInvokeInvokingExpectation():void
		{
			var invoked:int = 0;
			var invocation : MockInvocation = new MockInvocation('test', true);
			
			e.method('test')
				.andCall( function():void { invoked++; } )
				.andCall( function():void { invoked++; } )
				.andCall( function(args:Array=null):void { invoked++; } )
				.andCall( function(args:Array=null):void { invoked++; } );

			e.invoke( invocation );
			
			assertEquals( 4, invoked );
		}
		
		public function testFunctionsToCallShouldReceiveArgsFromInvoke():void
		{
			var invocation : MockInvocation = new MockInvocation('test', true, ['one', 2, true]);
			
			e.method('test').withAnyArgs.calls( function(...rest):void 
			{  
				assertEquals( 3, rest.length );
				assertEquals( rest[0], 'one' );
				assertEquals( rest[1], 2 );
				assertEquals( rest[2], true );
			});
			
			e.invoke( invocation );
		}
		
		// dispatching events
		public function testShouldSetEventToDispatchOnInvokingExpectation():void
		{
			var invoked:int = 0;
			var invocation : MockInvocation = new MockInvocation('test', true);
			/*var target:IEventDispatcher = mock.target as IEventDispatcher;*/
			
			mock.addEventListener( 'testEvent', function(e:Event):void { invoked++; } )
			
			e.method('test').andDispatchEvent( new Event('testEvent') );
			e.invoke( invocation );
			
			assertEquals( 1, invoked );
		}
		
		public function testShouldDispatchAllEventsSetOnExpectationWhenInvoked():void
		{
			var invoked:int = 0;
			var invocation : MockInvocation = new MockInvocation('test', true);
			/*var target:IEventDispatcher = mock.target as IEventDispatcher;*/
			
			mock.addEventListener( 'eventOne', function(e:Event):void { invoked++; } );
			mock.addEventListener( 'eventTwo', function(e:Event):void { invoked++; } );
			mock.addEventListener( 'verify', addAsync( function(e:Event):void
			{
				assertEquals( 2, invoked );
			}, 100, null ));
			
			e.method('test')
				.withNoArgs
				.dispatchesEvent( new Event('eventOne') )
				.dispatchesEvent( new Event('eventTwo') );
			
			// dispatches eventOne, and eventTwo
			e.invoke( invocation );
			
			// dispatch verify, which calls the function with assertEquals
			mock.dispatchEvent( new Event('verify') );
		}
				
		// verify messages sent
		// anything we would do here should be done in other test functions anyway
		/*public function testShouldVerifyIfAllExpectationsAreMet():void
		{
			fail();
		}*/
		
		public function testUnmetReceiveCountExpectationsShouldHaveNiceErrorMessages():void 
		{
			var invocation : MockInvocation = new MockInvocation('test', true, ["one", 2, true]);
			
			//e.method('test').withArgs(Boolean, Mock, function():void {}, "one", true, false, 3, Number, RegExp, /\d+/, String).once;
			e.method('test').withArgs("one", 2, true).atLeast(1).atMost(2);
			
			e.invoke(invocation);
			e.invoke(invocation);
			e.invoke(invocation);
			
			try 
			{
				e.verify();
				fail('Expecting an UnmetMockExpectationError to be thrown');
			}
			catch( error:MockExpectationError ) 
			{
				assertEquals(
					'Unmet Expectation: call test("one", 2, true) received: 3, expected: atLeast: 1 (+2), atMost: 2 (+1)',
					error.message);
			}
		}
	}
}