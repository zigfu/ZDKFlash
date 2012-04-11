package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
	import flash.events.AsyncErrorEvent;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;	
	import flash.display.StageDisplayState;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.events.NetStatusEvent;
	import flash.geom.Matrix;
	
	import com.adobe.serialization.json.JSON;
	
	import com.zigfu.ZDK;
	import com.zigfu.UserEvent;
	import com.zigfu.SessionEvent;
	
	import GestureableButton;
	
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
		
		var depthBM:Bitmap;
		var imageBM:Bitmap;
		var labelBM:Bitmap;
		var depthData:BitmapData;
		var imageData:BitmapData;
		var labelData:BitmapData;
		
		var histogram:Array;
		var labelColors:Array;
		var labelPixels:ByteArray;
		var depthPixels:ByteArray;
		
		var video:Video;
		var ns:NetStream;

		var activeButton:GestureableButton;
		
		// These will all go in an external conf file
		static const IDLE_VIDEO:String = 'Content/Filtrete Interactive Section Loop - Idle.f4v';
		static const BUTTONS_CONF:String = '[' + 
			'{"label":"Features", "video":"Content/Filtrete Interactive Section 2 - Product.f4v"},' +
			'{"label":"Filtration level", "video":"Content/Filtrete Interactive Section 3 - Benefits.f4v"},' +
			'{"label":"Installation", "video":"Content/Filtrete Interactive Section 4 - Installation.f4v"}' +
		']';
		
		// all normalized. should be pixel based??
		static const BUTTON_WIDTH:Number = 0.15;
		static const BUTTON_HEIGHT:Number = 0.22;
		static const BUTTON_PADDING:Number = 0.05;
		static const BUTTONS_CENTER_X:Number = 0.5;
		static const BUTTONS_CENTER_Y:Number = 0.65;
		
		// not normalized. whatevs
		static const BUTTONS_FRAME_PADDING:Number = 50;
		
		private function playVideo(path:String) {
			ns.play(path);
		}
		
		private function deactivate() {
			if (activeButton) {
				activeButton.setIdle();
				activeButton = null;
			}
			playVideo(IDLE_VIDEO);
		}
		
		private function activate(button:GestureableButton) {
			if (activeButton) {
				activeButton.setIdle();
			}
			activeButton = button;
			activeButton.setActive();
		}
		
		private function createButtons() {
			// parse json
			try {
				var buttons_parsed = JSON.decode(BUTTONS_CONF);
			} catch (e : Error) {
				debug("Error parsing config: " + e);
				return;
			}
			
			// quick out
			if (!buttons_parsed.length) return;
			
			// compute total buttons width, and top left corner to start drawing them from
			var totalWidth:Number = (buttons_parsed.length * BUTTON_WIDTH) + ((buttons_parsed.length - 1) * BUTTON_PADDING);
			var currTop:Number = BUTTONS_CENTER_Y - (BUTTON_HEIGHT / 2);
			var currLeft:Number = BUTTONS_CENTER_X - (totalWidth / 2);
			
			// create the frame
			
			for (var i in buttons_parsed) {
				// create the button
				var button:GestureableButton = new GestureableButton(buttons_parsed[i].label, BUTTON_WIDTH * stage.stageWidth, BUTTON_HEIGHT * stage.stageHeight);
				button.x = stage.stageWidth * currLeft;
				button.y = stage.stageHeight * currTop;
				button.addEventListener(MouseEvent.CLICK, (function(curr:Object, b:GestureableButton) { return function() {
					activate(b);
					playVideo(curr.video);
				};})(buttons_parsed[i], button));
				
				addChild(button);
				
				// advance positions
				currLeft += BUTTON_WIDTH + BUTTON_PADDING;
			}
		}
		
		private function rotateVideo(vid:Video, degrees:Number) {
			// Calculate rotation and offsets
			var radians:Number = degrees * (Math.PI / 180.0);
			//var offsetWidth:Number = vid.videoWidth/2.0;
			//var offsetHeight:Number =  vid.videoHeight/2.0;

			// Perform rotation
			var matrix:Matrix = new Matrix();
			//matrix.translate(-offsetWidth, -offsetHeight);
			matrix.rotate(radians);
			//matrix.translate(+offsetWidth, +offsetHeight);
			matrix.concat(vid.transform.matrix);
			vid.transform.matrix = matrix;
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			// @#$%^
			stage.align = "TL";
			
			users = { };
			zdk = new ZDK();
			zdk.addEventListener(UserEvent.USERFOUND, onUserFound);
			zdk.addEventListener(UserEvent.USERLOST, onUserLost);
			zdk.addEventListener("Update", onFrame);
			
			zdk.addEventListener(SessionEvent.SESSIONSTART, onSessionStart);
			zdk.addEventListener(SessionEvent.SESSIONUPDATE, onSessionUpdate);
			zdk.addEventListener(SessionEvent.SESSIONEND, onSessionEnd);
			
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler); 
			function asyncErrorHandler(event:AsyncErrorEvent):void { 
				debug("failed to load video");
				debug(event);
			}
			
			ns.addEventListener(NetStatusEvent.NET_STATUS, statusHandler); 
			function statusHandler(event:NetStatusEvent):void {
				switch (event.info.code) { 
					case "NetStream.Play.Start": break;
					case "NetStream.Play.Stop": {
						// deactivate & playidle
						deactivate();		
						break;
					}
				}
			}
			
			video = new Video(stage.stageWidth, stage.stageHeight);
			video.attachNetStream(ns);

			var client:Object = new Object(); 
			client.onMetaData = function(meta:Object) { 
				video.width = meta.width; 
				video.height = meta.height; 
			};
			ns.client = client;
			
			addChild(video);

			// play idle loop
			ns.play(IDLE_VIDEO); 
			
			createButtons();
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