package  {
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	public class SessionEvent extends Event
    {
        static public const SESSIONSTART:String = "SessionStart";
		static public const SESSIONUPDATE:String = "SessionUpdate";
		static public const SESSIONEND:String = "SessionEnd";
        
        protected var focusPosition:Vector3D;
		protected var handPosition:Vector3D;
		
        public function get FocusPosition():Vector3D { return focusPosition; }
		public function get HandPosition():Vector3D { return handPosition; }
        
        public function SessionEvent(type:String, focusPoint:Vector3D, handPoint:Vector3D){
            super(type, false, false);
            focusPosition = focusPoint;
			handPosition = handPoint;
        }
	}
}
