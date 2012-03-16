package 
{
	import flash.external.ExternalInterface;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Main extends Sprite 
	{
		var zdk:ZDK;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			debug("From inside flash");
			
			zdk = new ZDK();
			zdk.addEventListener(UserEvent.USERFOUND, onUserFound);
			zdk.addEventListener(UserEvent.USERLOST, onUserLost);
			zdk.addEventListener("Update", onFrame);
		}
		
		function onUserFound(e:UserEvent) {
			debug("User found: " + e.UserId);
		}
		
		function onUserLost(e:UserEvent) {
			debug("User lost: " + e.UserId);
		}
		
		function onFrame(e:Event) {
			
		}
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}