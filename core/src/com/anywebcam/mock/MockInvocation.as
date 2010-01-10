package com.anywebcam.mock
{
	public class MockInvocation
	{
		private var _propertyName : String;
		private var _isMethod : Boolean;
		private var _arguments : Array;
		
		public function MockInvocation(propertyName : String, isMethod : Boolean, args : Array = null) : void
		{
			this._propertyName = propertyName;
			this._isMethod = isMethod;
			this._arguments = args;
		}
		
		public function get propertyName() : String
		{
			return _propertyName;
		}
		
		public function get isMethod() : Boolean
		{
			return _isMethod;
		}
		
		public function get arguments() : Array
		{
			return _arguments;
		}
		
		public function toString() : String
		{
			var invocation : String = _isMethod ? "call" : (!_arguments ? "get" : "set");

			var args : String = _arguments && (_arguments.length > 0) 
				? _arguments.map(function(item:Object, index:int, array:Array ) : String {
						return (item is String) ? '"' + item + '"' : item.toString();
					}).join(", ") 
				: (_arguments && _arguments[0] ? _arguments[0] : '');
			
			var suffix : String = _isMethod ? ('(' + args + ')') : (args == '' ? '' : (' = ' + args));
				
			return invocation + ' ' + _propertyName + suffix;
		}
	}
}