package org.robotlegs.mvmcs
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import org.robotlegs.base.ContextError;
	import org.robotlegs.base.ViewMapBase;
	import org.robotlegs.core.IInjector;
	import org.robotlegs.core.IMediator;
	import org.robotlegs.core.IReflector;
	import org.robotlegs.core.IViewModelMap;

	public class ViewModelMap extends ViewMapBase implements IViewModelMap
	{
		protected static var enterFrameDispatcher:Sprite;
		
		protected var viewModelAndMediatorByView:Dictionary;
		
		protected var mappingConfigByViewClassName:Dictionary;

		protected var viewModelsMarkedForRemoval:Dictionary;
		
		protected var hasViewModelsMarkedForRemoval:Boolean;
		
		protected var reflector:IReflector;
		
		
		public function ViewModelMap(contextView:DisplayObjectContainer, injector:IInjector, reflector:IReflector)
		{
			super(contextView, injector);
			
			this.reflector = reflector;
			
			this.viewModelAndMediatorByView = new Dictionary(true);
			this.mappingConfigByViewClassName = new Dictionary(false);
			this.viewModelsMarkedForRemoval = new Dictionary(false);
		}
		
		
		public function mapView(viewClassOrName:*, viewModelClass:Class, mediatorClass:Class = null, autoCreate:Boolean = true, autoRemove:Boolean = true):void
		{
			var viewClassName:String = reflector.getFQCN(viewClassOrName);
			
			if (mappingConfigByViewClassName[viewClassName] != null)
				throw new ViewModelMapError(ViewModelMapError.E_VIEWMODELMAP_OVR + " - " + viewModelClass);
			
			if (mediatorClass != null && reflector.classExtendsOrImplements(mediatorClass, IMediator) == false)
				throw new ContextError(ContextError.E_MEDIATORMAP_NOIMPL + ' - ' + mediatorClass);
			
			var config:MappingConfig = new MappingConfig();
			config.viewModelClass = viewModelClass;
			config.mediatorClass = mediatorClass;
			config.viewClass = viewClassOrName;
			config.autoCreate = autoCreate;
			config.autoRemove = autoRemove;
			mappingConfigByViewClassName[viewClassName] = config;
			
			if (autoCreate || autoRemove)
			{
				viewListenerCount++;
				if (viewListenerCount == 1)
					addListeners();
			}
		}
		
		
		public function unmapView(viewClassOrName:*):void
		{
			var viewClassName:String = reflector.getFQCN(viewClassOrName);
			var config:MappingConfig = mappingConfigByViewClassName[viewClassName];
			if (config && (config.autoCreate || config.autoRemove))
			{
				viewListenerCount--;
				if (viewListenerCount == 0)
					removeListeners();
			}
			delete mappingConfigByViewClassName[viewClassName];
		}
		
		
		override protected function addListeners():void
		{
			if (contextView && enabled)
			{
				contextView.addEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture, 0, true);
//				contextView.addEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture, 0, true);
			}
		}
		
		
		override protected function removeListeners():void
		{
			if (contextView)
			{
				contextView.removeEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture);
				for (var viewComponent:Object in viewModelAndMediatorByView)
				{
					if (viewComponent is InteractiveObject)
						(viewComponent as InteractiveObject).removeEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved);
				}
//				contextView.removeEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture);
			}
		}
		
		
		override protected function onViewAdded(e:Event):void
		{
			
			if (viewModelsMarkedForRemoval[e.target])
			{
				delete viewModelsMarkedForRemoval[e.target];
				return;
			}
			var viewClassName:String = getQualifiedClassName(e.target);
			var config:MappingConfig = mappingConfigByViewClassName[viewClassName];
			if (config && config.autoCreate)
				createViewModelUsing(e.target, viewClassName, config);
		}
		
		
		protected function createViewModelUsing(viewComponent:Object, viewClassName:String = "", config:MappingConfig = null):void
		{
			var viewModelCache:CachedModel = viewModelAndMediatorByView[viewComponent];
			if (viewModelCache == null)
			{
				viewClassName ||= getQualifiedClassName(viewComponent);
				config ||= mappingConfigByViewClassName[viewClassName];
				if (config)
				{
					var viewModel:Object = injector.instantiate(config.viewModelClass);
					injector.mapValue(config.viewModelClass, viewModel);
					injector.injectInto(viewComponent);
					if (config.mediatorClass != null)
						var mediator:IMediator = injector.instantiate(config.mediatorClass);
					injector.unmap(config.viewModelClass);
					// registerViewModel:
					viewModelCache = new CachedModel();
					viewModelCache.viewModel = viewModel;
					viewModelAndMediatorByView[viewComponent] = viewModelCache;
					if (config.mediatorClass != null)
					{
						viewModelCache.mediator = mediator;
						mediator.setViewComponent(viewComponent);//?
						mediator.preRegister();//?
					}
				}
			}
			
			if (viewComponent is InteractiveObject)
				(viewComponent as InteractiveObject).addEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved);
		}
		
		
		protected function onViewRemoved(e:Event):void
		{
			if (e.target is InteractiveObject)
				(e.target as InteractiveObject).removeEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved);
			
			var viewClassName:String = getQualifiedClassName(e.target);
			var config:MappingConfig = mappingConfigByViewClassName[viewClassName];
			if (config != null && config.autoRemove)
			{
				viewModelsMarkedForRemoval[e.target] = e.target;
				if (!hasViewModelsMarkedForRemoval)
				{
					hasViewModelsMarkedForRemoval = true;
					enterFrameDispatcher ||= new Sprite();
					enterFrameDispatcher.addEventListener(Event.ENTER_FRAME, removeViewModelLater);
				}
			}
		}
		
		
		protected function removeViewModelLater(event:Event):void
		{
			enterFrameDispatcher.removeEventListener(Event.ENTER_FRAME, removeViewModelLater);
			for each (var view:DisplayObject in viewModelsMarkedForRemoval)
			{
				if (view.stage == null)
				{
					// removeViewModelByView(view);
						// removeViewModel(retrieveViewModel(view))
					var model:CachedModel = viewModelAndMediatorByView[view];
					if (model != null)
					{
						delete viewModelAndMediatorByView[view];
						if (model.mediator != null)
						{
							model.mediator.preRemove();
							model.mediator.setViewComponent(null);
						}
					}
				}
				delete viewModelsMarkedForRemoval[view];
			}
			hasViewModelsMarkedForRemoval = false;
		}
	}
}
import org.robotlegs.core.IMediator;

class MappingConfig
{
	public var viewModelClass:Class;
	public var mediatorClass:Class;
	public var viewClass:*;
	public var autoCreate:Boolean;
	public var autoRemove:Boolean;
}

class CachedModel
{
	public var viewModel:Object;
	public var mediator:IMediator;
}