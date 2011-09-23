package org.robotlegs.core
{
	import mx.messaging.AbstractConsumer;

	public interface IViewModelMap
	{
		function mapView(viewClassOrName:*, viewModelClass:Class, mediatorClass:Class = null, autoCreate:Boolean = true, autoRemove:Boolean = true):void;
		
		function unmapView(viewClassOrName:*):void;
	}
}