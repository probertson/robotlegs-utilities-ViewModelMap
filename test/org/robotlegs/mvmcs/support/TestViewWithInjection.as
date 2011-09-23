package org.robotlegs.mvmcs.support
{
	public class TestViewWithInjection extends TestView
	{
		[Inject]
		public var utility:DummyUtilityClass;
	}
}