package 
{
	import flash.display.Bitmap;
	import flash.external.ExternalInterface;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Main extends Sprite 
	{
		var zdk:ZDK;
		var users:Dictionary;
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
			debug("Flash User found: " + e.UserId);
			debug(e.UserId);
			var u:Shape = new Shape();
			u.graphics.beginFill(0x0000FF);
			u.graphics.drawRect(0, 0, 50, 50);
			u.graphics.endFill();
			this.addChild(u);
			debug(u.x);
			users[e.UserId] = u;
			debug("users set: " + users[e.UserId].x);
		}
		
		function onUserLost(e:UserEvent) {
			debug("Flash User lost: " + e.UserId);
			this.removeChild(users[e.UserId]);
			delete users[e.UserId];
		}
		
		function onFrame(e:Event) {
			
			for (var userid in users)
			{
				debug(userid);
			}
		/*		var u:Shape = users[userid];			
				var pos = zdk.trackedUsers[userid].centerofmass;
				
				var point:Point = new Point();
				point.x = (1.0 - ((pos[0] / 4000.0) + 0.5)) * 400 - (u.width / 2);	
				point.y = (pos[2] / 4000.0) * 400 - (u.height / 2);
				u.x = point.x;
				u.y = point.y;	
			}*/
		}
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}