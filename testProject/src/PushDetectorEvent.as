package  
{
	import flash.events.Event;
	
	public class PushDetectorEvent extends Event 
	{
		static public const PUSH:String = "Push";
		static public const RELEASE:String = "Release";
		static public const CLICK:String = "Click";
		
		var _pd:PushDetector;
		public function get pushDetector():PushDetector {
			return _pd;
		}
		
		public function PushDetectorEvent(type:String, pd:PushDetector) { 
			super(type, false, false);
			_pd = pd;
		} 
	}
}