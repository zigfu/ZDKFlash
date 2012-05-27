package 
{
	import digicrafts.album.screenobject.away3d.DockMenuObject;
	import flash.display.MovieClip;
	import digicrafts.events.ItemEvent;
	import digicrafts.events.DataSourceEvent;
	import digicrafts.events.HCIManagerEvent;
	import digicrafts.flash.controls.DockMenu3D;
	import digicrafts.events.ResourceLoaderEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
	import flash.events.AsyncErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
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
	import flash.utils.setTimeout;
	import flash.display.StageDisplayState;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.AntiAliasType;
	import flash.events.NetStatusEvent;
	import flash.geom.Matrix;
	import flash.text.Font;
	import flash.utils.Timer;
	
	import com.zigfu.ZDK;
	import com.zigfu.UserEvent;
	import com.zigfu.SessionEvent;
	
	import GestureableButton;
	
	//internals of the DockMenu3D control
	import away3d.containers.View3D;
	import digicrafts.album.screen.Screen3D;
	import digicrafts.album.DockMenu3D;
	import away3d.events.MouseEvent3D;
	import away3d.core.base.Object3D;
	import away3d.core.project.MovieClipSpriteProjector;
	import away3d.events.MouseEvent3D;
	import away3d.materials.MovieMaterial;

	import away3d.arcane; 
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Main extends Sprite 
	{
		[Embed(source = "../fonts/verdana.ttf", fontFamily = "Arial", embedAsCFF = "false")] public var Arial:Class;
		
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
		
		var TIMER_TICK_COUNT:Number = 60 * 0.8; // 60 FPS * time in seconds
		var selectTimer:Timer;
		var videoToPlay:String;
		
		var activeButton:GestureableButton;
		var overlay:Overlay;
		
		var fader:Fader;
		var pushDetector:PushDetector;
		
		var controls:Array = [];
		
		var dm3d:digicrafts.flash.controls.DockMenu3D;
		var view:View3D;
		var mouseStartX:Number;
		var mouseWidth:Number;
		var mouseStartY:Number;
		
		var activeSimpleButton:SimpleButton;
		var backupState:DisplayObject;
		
		var playingContent:Boolean = false; // non idle
		var playingProductVideo:Boolean = false; // non idle & activity
		
		// These will all go in an external conf file
		static const IDLE_VIDEO:String = 'sidVideos/3M SID Standee Loop 1024.f4v';
		//static const ACTIVITY_VIDEO:String = 'Content/Filtrete Interactive Section 1 Shortened.f4v';
			
		var videoFiles = [
			"sidVideos/3M SID Deep Dive 1 1024.f4v",
			"sidVideos/3M SID Deep Dive 2 1024.f4v",
			"sidVideos/3M SID Deep Dive 3 1024.f4v",
			"sidVideos/3M SID Deep Dive 5 1024.f4v",
			"sidVideos/3M SID Deep Dive 6 1024.f4v",
			"sidVideos/3M SID Deep Dive 7 1024.f4v"
		];
		
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
						ns.play(IDLE_VIDEO);
						playingContent = false;
						
						if (zdk.usersCount > 0) {
							overlay.showSessionPrompt();
						}
						/*
						if (zdk.usersCount == 0) {
							ns.play(IDLE_VIDEO);
							playingContent = false;
						} else {
							ns.play(ACTIVITY_VIDEO);
							playingContent = true;
							overlay.showSessionPrompt();
						}*/
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
				// video selection wont happen through this callback anymore, do nothing
				/*playingContent = true;
				playingProductVideo = true;
				playVideo(vid);*/
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
				//overlay.visualizeFader(fe.fader.value);
				view.fireMouseEvent(MouseEvent3D.MOUSE_MOVE, mouseStartX + fe.fader.value * mouseWidth, mouseStartY);
			});
			
			pushDetector = new PushDetector();
			pushDetector.addEventListener(PushDetectorEvent.CLICK, function(pde:PushDetectorEvent) {
				overlay.activate(fader.hoverItem);
			});
			
			controls.push(fader);
			controls.push(pushDetector);
			
			// dockmenu3d
			dm3d = new digicrafts.flash.controls.DockMenu3D();
			dm3d.addEventListener(DataSourceEvent.BUFFER_COMPLETE , function(e:Object) { 
				setTimeout(function() {
					rotateSprite(dm3d, 270);
					//dm3d.visible = true;
					setTimeout(setupMouse, 500);
				}, 200);
			});

			dm3d.load("media/menu.xml");
			dm3d.x = 580;
			dm3d.y = 330;
			dm3d.mask = null;
			dm3d.itemWidth = 52;
			dm3d.itemHeight = 52;
			addChild(dm3d);
			
			var format:TextFormat = new TextFormat("Arial");
			format.color = 0xFFFFFF;
			format.size = 18;
			format.bold = false;
			format.align = TextFormatAlign.CENTER;
			
			dm3d.tooltip.label = new TextField();
			dm3d.tooltip.label.embedFonts = true;
			dm3d.tooltip.font = "Arial";
			dm3d.tooltip.textFormat = format;
			dm3d.tooltip.label.setTextFormat(format);
			dm3d.tooltip.label.defaultTextFormat = format;
			dm3d.tooltip.addChild(dm3d.tooltip.label);
			dm3d.tooltip.label.antiAliasType = AntiAliasType.ADVANCED;
			dm3d.visible = false;
							
			selectTimer = new Timer(1.0 / 60.0, TIMER_TICK_COUNT);
			selectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function() {
				playVideo(videoToPlay);
				playingContent = true;
				playingProductVideo = true;
			});
			
			dm3d.addEventListener(ItemEvent.MOUSE_OVER, function(evt:ItemEvent) {
				var dockobj:DockMenuObject = evt.obj as DockMenuObject;
				// move the indicator
				dockobj.startAnimation();
				// start button animation
				var mc:MovieClip = dockobj.itemData.source.source.resource as MovieClip;
				var btn:SimpleButton = mc.getChildAt(0) as SimpleButton;
				backupState = btn.upState;
				btn.upState = btn.overState;
				
				// start timer
				videoToPlay = videoFiles[evt.index];
				selectTimer.reset();
				selectTimer.start();
			});

			dm3d.addEventListener(ItemEvent.MOUSE_OUT, function(evt:ItemEvent) {
				var dockobj:DockMenuObject = evt.obj as DockMenuObject;
				dockobj.stopAnimation();
				var mc:MovieClip = dockobj.itemData.source.source.resource as MovieClip;
				var btn:SimpleButton = mc.getChildAt(0) as SimpleButton;
				btn.upState = backupState;
				
				// stop timer
				selectTimer.stop();
			});
		}
		
		function onUserFound(e:UserEvent) {
			Track.track('userfound', { 'userid' : e.UserId });
			
			if (!zdk.inSession && !playingProductVideo) {
				overlay.showSessionPrompt();
				dm3d.visible = false;
			}
			/*
			if (!playingContent) {
				playVideo(ACTIVITY_VIDEO);
				playingProductVideo = false;
				playingContent = true;
			}*/
		}
		
		function onUserLost(e:UserEvent) {
			Track.track('userlost', { 'userid' : e.UserId });
			
			var usersCount = 0;
			if (0 == zdk.usersCount) {
				overlay.hide();
				dm3d.visible = false;
			}
		}
		
		function onFrame(e:Event) {
			
		}
		
		function vectorToArray(v:Vector3D):Array {
			return [v.x, v.y, v.z];
		}
		
		function onSessionStart(e:SessionEvent) {
			Track.track('sessionstart', { 'userid' : e.UserId});
			
			overlay.hide();
			dm3d.visible = true;
			
			// fake mouse over in a way that doesn't check internally whether the mouse is actually
			// hovering over the control in a way we can't intercept
			view.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER)); 
			
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
			
			// fake mouse leaving the dock
			view.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT)); 
			
			controls.forEach(function(cont, i) {
				cont.onsessionend();
			});
		
			dm3d.visible = false;
			if (!playingProductVideo) {
				overlay.showSessionPrompt();
			} else {
				overlay.hide();
			}
		}
		
		function setupMouse() {
			view = ((dm3d.getChildAt(0) as digicrafts.album.DockMenu3D).getChildAt(0) as Screen3D).getChildAt(0) as View3D;
			mouseStartX = -dm3d.width / 3;
			mouseWidth = (dm3d.width * 2) / 3;
			mouseStartY = 0;
			view._screenClipping.maxX += 100;
		}
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}