package away3d.containers
{
	import away3d.containers.View3D
	import away3d.arcane;
	import flash.events.MouseEvent;
	use namespace away3d.arcane;
	/**
	 * ...
	 * @author zigfu
	 */
	dynamic public class setvar extends View3D
	{
		
		public function setvar() 
		{
			
		}
		
		public static function setMouseOver(view : View3D) {
			//view._mouseIsOverView = b;
			view.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		}
		
	}

}