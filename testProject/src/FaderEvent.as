package  
{
	import flash.events.Event;
	
	public class FaderEvent extends Event 
	{
        static public const HOVERSTART:String = "HoverStart";
		static public const HOVERSTOP:String = "HoverStop";
		static public const VALUECHANGE:String = "ValueChange";
		static public const EDGE:String = "Edge";
	
		var _fader:Fader;
		
		public function get fader():Fader {
			return _fader;
		}
		
		public function FaderEvent(type:String, f:Fader) { 
			super(type, false, false);
			_fader = f;
		}
	}
}