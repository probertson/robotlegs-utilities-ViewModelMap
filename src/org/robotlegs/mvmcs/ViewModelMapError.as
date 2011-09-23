package org.robotlegs.mvmcs
{
	import org.robotlegs.base.ContextError;
	
	public class ViewModelMapError extends ContextError
	{
		public static const E_VIEWMODELMAP_OVR:String = "View Class has already been mapped to a ViewModel class in this context";
		
		public function ViewModelMapError(message:String = "", id:int = 0)
		{
			super(message, id);
		}
	}
}