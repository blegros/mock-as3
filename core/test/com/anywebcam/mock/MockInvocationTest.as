package com.anywebcam.mock
{
	import org.flexunit.Assert;

	public class MockInvocationTest
	{
		private var fixture : MockInvocation;
		
		[Test]
		public function testToStringWithMethodHavingNoArgs() : void
		{
			fixture = new MockInvocation('testMethod', true);
			Assert.assertEquals("call testMethod()", fixture.toString());
		}
		
		[Test]
		public function testToStringWithMethodHavingArgs() : void
		{
			fixture = new MockInvocation('testMethod', true, [1, "test", String]);
			Assert.assertEquals("call testMethod(1, \"test\", [class String])", fixture.toString());
		}
		
		[Test]
		public function testToStringWithPropertyGetter() : void
		{
			fixture = new MockInvocation('testProperty', false);
			Assert.assertEquals("get testProperty", fixture.toString()); 
		}
		
		[Test]
		public function testToStringWithPropertySetter() : void
		{
			fixture = new MockInvocation('testProperty', false, ["blah"]);
			Assert.assertEquals("set testProperty = \"blah\"", fixture.toString());
		}
	}
}