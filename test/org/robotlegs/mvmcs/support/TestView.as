package org.robotlegs.mvmcs.support
{
	import flash.display.Sprite;
	
	public class TestView extends Sprite
	{
		[Inject]
		public var pm:TestViewModel;
		
		
		public function TestView()
		{
			super();
		}
	}
}