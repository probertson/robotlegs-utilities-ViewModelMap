package org.robotlegs.mvmcs
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertNotNull;
	import org.hamcrest.object.nullValue;
	import org.robotlegs.adapters.SwiftSuspendersInjector;
	import org.robotlegs.adapters.SwiftSuspendersReflector;
	import org.robotlegs.core.IInjector;
	import org.robotlegs.core.IReflector;
	import org.robotlegs.mvmcs.support.DummyUtilityClass;
	import org.robotlegs.mvmcs.support.TestView;
	import org.robotlegs.mvmcs.support.TestViewModel;
	import org.robotlegs.mvmcs.support.TestViewWithInjection;
	
	public class ViewModelMap_mapView
	{
		// ------- Instance to test -------
		
		private var _instance:ViewModelMap;
		
		
		// ------- Utility vars -------
		
		private var _contextView:DisplayObjectContainer;
		private var _injector:IInjector;
		
		
		// ------- Setup/Teardown -------
		
		[Before]
		public function setUp():void
		{
			_contextView = new Sprite();
			_injector = new SwiftSuspendersInjector();
			var reflector:IReflector = new SwiftSuspendersReflector();
			
			_instance = new ViewModelMap(_contextView, _injector, reflector);
		}
		
		
		[After]
		public function tearDown():void
		{
			while (_contextView.numChildren > 0)
				_contextView.removeChildAt(0);
			
			_contextView = null;
			_injector = null;
			_instance = null;
		}
		
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		
		// ------- Test methods -------
		
		[Test]
		public function test_afterCallingMapView_whenViewDispatchesAddedToStageEvent_viewModelIsInjectedIntoView():void
		{
			_instance.mapView(TestView, TestViewModel);
			
			var view:TestView = new TestView();
			_contextView.addChild(view);
			view.dispatchEvent(new Event(Event.ADDED_TO_STAGE, true));
			
			assertNotNull(view.pm);
		}
		
		
		[Test]
		public function test_afterCallingMapView_withANonViewModelClassMappedForInjection_theNonViewModelInstanceIsInjectedIntoView():void
		{
			var utilityObject:DummyUtilityClass = new DummyUtilityClass();
			_injector.mapValue(DummyUtilityClass, utilityObject);
			
			_instance.mapView(TestViewWithInjection, TestViewModel);
			
			var view:TestViewWithInjection = new TestViewWithInjection();
			_contextView.addChild(view);
			view.dispatchEvent(new Event(Event.ADDED_TO_STAGE, true));
			
			assertEquals(utilityObject, view.utility);
		}
		
		
		// after calling mapView, when view is added then removed then added again, same view model is re-injected?
		// after calling mapView with a view class mapped as an interface, viewModel is injected into view
		// after calling mapView with a viewModel class mapped as an interface, viewModel is injected into view?
		// after calling mapView, viewModel is injected into mediator with mapping for viewmodel type
		
		// after calling mapView with viewModel mapped as a concrete type, viewModel is injected into mediator with mapping for interface that viewModel implements?
		// -or-
		// after calling mapView with viewModel mapped as an interface, viewModel is injected into mediator with mapping for interface type?
		
		// after calling mapView, view is injected into mediator
	}
}