package 
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
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
		var users:Object;
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			// @#$%^
			stage.align = "TL";
		
			var back:Shape = new Shape();
			back.graphics.lineStyle(6, 0x8080FF, 1);
			back.graphics.beginFill(0xFFFFFF);
			back.graphics.drawRect(3, 3, stage.stageWidth-6, stage.stageHeight-6);
			back.graphics.endFill();
			addChild(back);
			
			users = { };
			zdk = new ZDK();
			zdk.addEventListener(UserEvent.USERFOUND, onUserFound);
			zdk.addEventListener(UserEvent.USERLOST, onUserLost);
			zdk.addEventListener("Update", onFrame);
			
			zdk.addEventListener(SessionEvent.SESSIONSTART, onSessionStart);
			zdk.addEventListener(SessionEvent.SESSIONUPDATE, onSessionUpdate);
			zdk.addEventListener(SessionEvent.SESSIONEND, onSessionEnd);
		}
		
		function onUserFound(e:UserEvent) {
			debug("Flash user: " + e.UserId);
			var u:Shape = new Shape();
			u.graphics.lineStyle(4, 0xF233FC, 1);
			u.graphics.beginFill(0x0000FF);
			u.graphics.drawRoundRect(0, 0, 40, 40, 20);
			u.graphics.endFill();
			this.addChild(u);
			users[e.UserId] = u;
		}
		
		function onUserLost(e:UserEvent) {
			debug("Flash User lost: " + e.UserId);
			this.removeChild(users[e.UserId]);
			delete users[e.UserId];
		}
		
		function onFrame(e:Event) {
			for (var userid in users)
			{
				var u:Shape = users[userid];			
				var pos = zdk.trackedUsers[userid].centerofmass;
				
				var point:Point = new Point();
				point.x = ((pos[0] / 4000.0) + 0.5);
				point.y = (pos[2] / 4000.0);
				point.x = (point.x * stage.stageWidth) - (u.width / 2);
				point.y = (point.y * stage.stageHeight) - (u.height / 2);
				u.x = point.x;
				u.y = point.y;	
			}
		}
		
		function onSessionStart(e:SessionEvent) {
			debug("Session start");
		}
		
		function onSessionUpdate(e:SessionEvent) {
			debug("Session update: " + e.HandPosition);
		}
		
		function onSessionEnd(e:SessionEvent) {
			debug("Session end");
		}
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}