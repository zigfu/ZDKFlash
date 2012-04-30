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
	import flash.geom.Vector3D;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequestHeader;
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
		var overlay:Overlay;
		
		var fader:Fader;
		var pushDetector:PushDetector;
		
		var controls:Array = [];
		
		var playingContent:Boolean = false; // non idle
		var playingProductVideo:Boolean = false; // non idle & activity
		
		// These will all go in an external conf file
		static const IDLE_VIDEO:String = 'Content/Filtrete Interactive Section Loop.f4v';
		static const ACTIVITY_VIDEO:String = 'Content/Filtrete Interactive Section 1 Shortened.f4v';
			
		private function playVideo(path:String) {
			ns.play(path);
		}
	
		private function rotateSprite(spr:Sprite, degrees:Number) {
			// Calculate rotation and offsets
			var radians:Number = degrees * (Math.PI / 180.0);
			var offsetWidth:Number = spr.width/2.0;
			var offsetHeight:Number =  spr.height/2.0;

			// Perform rotation
			var matrix:Matrix = new Matrix();
			matrix.translate(-offsetWidth, -offsetHeight);
			matrix.rotate(radians);
			matrix.translate(+offsetWidth, +offsetHeight);
			matrix.concat(spr.transform.matrix);
			spr.transform.matrix = matrix;
		}
		
		private function rotateVideo(vid:Video, degrees:Number) {
			// Calculate rotation and offsets
			var radians:Number = degrees * (Math.PI / 180.0);
			var offsetWidth:Number = vid.videoWidth/2.0;
			var offsetHeight:Number =  vid.videoHeight/2.0;

			// Perform rotation
			var matrix:Matrix = new Matrix();
			matrix.translate(-offsetWidth, -offsetHeight);
			matrix.rotate(radians);
			matrix.translate(+offsetWidth, +offsetHeight);
			matrix.concat(vid.transform.matrix);
			vid.transform.matrix = matrix;
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			Track.track("init");
			
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
					case "NetStream.Play.Stop":
						// deactivate & playidle
						overlay.deactivate();
						// TODO: refactor
						playingProductVideo = false;
						if (zdk.usersCount == 0) {
							ns.play(IDLE_VIDEO);
							playingContent = false;
						} else {
							ns.play(ACTIVITY_VIDEO);
							playingContent = true;
							overlay.showSessionPrompt();
						}
						break;
				}
			}
			
			video = new Video(1024, 768);
			video.attachNetStream(ns);
			var client:Object = new Object(); 
			ns.client = client;
			addChild(video);

			// play idle loop
			ns.play(IDLE_VIDEO); 
			
			overlay = new Overlay(550, 85, [ 
				{"label":"Product", "video":"Content/Filtrete Interactive Section 2.f4v"},
				{"label":"Benefits", "video":"Content/Filtrete Interactive Section 3.f4v"},
				{"label":"Installation", "video":"Content/Filtrete Interactive Section 4.f4v" }
			], function(vid) {
				playingContent = true;
				playingProductVideo = true;
				playVideo(vid);
			});
			
			overlay.x = 310;
			overlay.y = -10;
			rotateSprite(overlay, 270);
			
			addChild(overlay);
			
			fader = new Fader(Fader.ORIENTATION_X, 300);
			fader.itemsCount = 3;
			fader.addEventListener(FaderEvent.HOVERSTART, function(fe:FaderEvent) {
				overlay.hover(fe.fader.hoverItem);
			});
			fader.addEventListener(FaderEvent.HOVERSTOP, function(fe:FaderEvent) {
				overlay.unhover(fe.fader.hoverItem);
			});
			fader.addEventListener(FaderEvent.VALUECHANGE, function(fe:FaderEvent) {
				overlay.visualizeFader(fe.fader.value);
			});
			
			pushDetector = new PushDetector();
			pushDetector.addEventListener(PushDetectorEvent.CLICK, function(pde:PushDetectorEvent) {
				overlay.activate(fader.hoverItem);
			});
			
			controls.push(fader);
			controls.push(pushDetector);
		}
		
		function onUserFound(e:UserEvent) {
			Track.track('userfound', { 'userid' : e.UserId });
			
			if (!zdk.inSession && !playingProductVideo) {
				overlay.showSessionPrompt();
			}
			if (!playingContent) {
				playVideo(ACTIVITY_VIDEO);
				playingProductVideo = false;
				playingContent = true;
			}
		}
		
		function onUserLost(e:UserEvent) {
			Track.track('userlost', { 'userid' : e.UserId });
			
			var usersCount = 0;
			if (0 == zdk.usersCount) {
				overlay.hide();
			}
		}
		
		function onFrame(e:Event) {
			
		}
		
		function vectorToArray(v:Vector3D):Array {
			return [v.x, v.y, v.z];
		}
		
		function onSessionStart(e:SessionEvent) {
			Track.track('sessionstart', { 'userid' : e.UserId});
			
			overlay.showButtons();
			var pos = vectorToArray(e.FocusPosition);
			controls.forEach(function(cont, i) {
				cont.onsessionstart(pos);
			});
		}
		
		function onSessionUpdate(e:SessionEvent) {
			var pos = vectorToArray(e.HandPosition);
			controls.forEach(function(cont, i) {
				cont.onsessionupdate(pos);
			});
		}
		
		function onSessionEnd(e:SessionEvent) {
			Track.track('sessionend');
			
			controls.forEach(function(cont, i) {
				cont.onsessionend();
			});
		
			if (!playingProductVideo) {
				overlay.showSessionPrompt();
			} else {
				overlay.hide();
			}
		}
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}