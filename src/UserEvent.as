package  {
	import flash.events.Event;
	
	public class UserEvent extends Event
    {
        static public const USERFOUND:String = "UserFound";
		static public const USERLOST:String = "UserLost";
        
        protected var userId:int;
        public function get UserId():int { return userId; }
        
        public function UserEvent(type:String, userid:int){
            super(type, false, false);
            userId = userid;
        }
	}
}
