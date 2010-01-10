package com.anywebcam.mock
{
    import asx.array.compact;
    import asx.array.flatten;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.system.ApplicationDomain;
    import flash.utils.Dictionary;
    
    import org.floxy.IProxyRepository;
    import org.floxy.ProxyRepository;

    public class Mockery extends EventDispatcher
    {
        private var mocksByTarget:Dictionary;
        private var proxyRepository:IProxyRepository;
        private var prepareProxyDispatchers:Array;
        private var _nextNameIndex:int;

        public function Mockery()
        {
            proxyRepository = new ProxyRepository();
            prepareProxyDispatchers = [];
            mocksByTarget = new Dictionary();
            
            _nextNameIndex = 0;
        }

        public function prepare(... classes):void
        {
            classes = flatten(classes);
            
            var dispatcher:IEventDispatcher = proxyRepository.prepare(classes, ApplicationDomain.currentDomain);
            dispatcher.addEventListener(Event.COMPLETE, function(event:Event):void
                {
                    dispatchEvent(event)
                });
            prepareProxyDispatchers.push(dispatcher);
        }

        public function nice(classToMock:Class, constructorArgs:Array=null):*
        {
            return create(classToMock, constructorArgs, true);
        }

        public function strict(classToMock:Class, constructorArgs:Array=null):*
        {
            return create(classToMock, constructorArgs, false);
        }
        
        public function create(classToMock:Class, constructorArgs:Array=null, nicely:Boolean=true, name:String=null):*
        {
            var interceptor:MockInterceptor = new MockInterceptor();
            var target:* = proxyRepository.create(classToMock, constructorArgs || [], interceptor);
            var mock:Mock = new Mock(target, nicely, name ? name : "Mockery$" + _nextNameIndex++);
            interceptor.mock = mock;
            mocksByTarget[target] = mock;
            return target;
        }

        public function mock(target:Object):Mock
        {
            return mocksByTarget[target] as Mock;
        }

        public function verify(targets : Array):void
        {
			var errors : Array = [];
			
            targets = compact(flatten(targets));
            
            for each (var target:Object in targets)
            {
                var mock:Mock = mocksByTarget[target] as Mock;
                if (mock)
                {
					try
					{
						mock.verify();
					}
					catch(error : MockExpectationError)
					{
						errors.push(error);
					}
                }
            }
			
			if(errors.length > 0)
			{
				var message : String = errors.map( function( item:MockExpectationError, index:int, array:Array) : String {
						return item.message;
					}).join("\n\n");
				
				throw new MockExpectationError(message);
			}
        }
		
		public function reset() : void
		{
			mocksByTarget = new Dictionary();
		}
    }
}