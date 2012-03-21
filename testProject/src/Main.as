package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
	import flash.external.ExternalInterface;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import com.zigfu.ZDK;
	import com.zigfu.UserEvent;
	import com.zigfu.SessionEvent;
	
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
			try{
			// image/label/depth displays
			depthData = new BitmapData(ZDK.mapWidth, ZDK.mapHeight, false);
			imageData = new BitmapData(ZDK.mapWidth, ZDK.mapHeight, false);
			labelData = new BitmapData(ZDK.mapWidth, ZDK.mapHeight, false);
			depthBM = new Bitmap(depthData);
			imageBM = new Bitmap(imageData);
			labelBM = new Bitmap(labelData);
			depthBM.scaleX = depthBM.scaleY = 2;
			labelBM.scaleX = labelBM.scaleY = 2;
			imageBM.scaleX = imageBM.scaleY = 2;
			labelBM.x = 320;
			imageBM.x = 640;
			histogram = new Array();
			for (var i = 0; i < ZDK.maxDepth; i++) {
				histogram[i] = 0;
			}
			labelColors = [0xffff0000, 0xff00ff00, 0xff0000ff];
			labelPixels = labelData.getPixels(new Rectangle(0, 0, labelData.width, labelData.height));
			depthPixels = depthData.getPixels(new Rectangle(0, 0, depthData.width, depthData.height));
			
			addChild(imageBM);
			addChild(labelBM);
			addChild(depthBM);
			} catch (err:Error) {
				debug("failed initializing shit");
				debug(err.toString());
			}
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
			
			//update the various images
			try{
			// RGB
			imageData.setPixels(new Rectangle(0, 0, ZDK.mapWidth, ZDK.mapHeight), zdk.imageMap);
			//depth
			for (var i = 0; i < ZDK.maxDepth; i++) {
				histogram[i] = 0;
			}
			var depth:ByteArray = zdk.depthMap;
			var numPoints:int = 0;
			depth.position = 0;
			for (var i = 0; i < ZDK.mapWidth * ZDK.mapHeight; i++) {
				var pixel:uint = depth.readUnsignedShort();
				if (pixel > 0) {
					histogram[pixel]++;
					numPoints++;
				}
			}
			
			for (var i = 1; i < ZDK.maxDepth; i++) {
				histogram[i] += histogram[i-1];
			}
			// now convert histogram to pixel values
			for (var i = 1; i < ZDK.maxDepth; i++) {
				// doing it all in fixed point
				var intensity:uint = (255 * (numPoints - histogram[i])) / numPoints;
				histogram[i] = 0xff000000 | (intensity << 8) | intensity;
			}
			histogram[0] = 0xff000000; // set pixel to black
			// now do a copy through histogram lookup
			depth.position = 0;
			depthPixels.position = 0;
			for (var i = 0; i < ZDK.mapWidth * ZDK.mapHeight; i++) {
				depthPixels.writeInt(histogram[depth.readUnsignedShort()]);
			}
			depthPixels.position = 0;
			depthData.setPixels(new Rectangle(0, 0, ZDK.mapWidth, ZDK.mapHeight), depthPixels);
			
			// user segmentation
			labelPixels.position = 0;
			var label:ByteArray = zdk.labelMap;
			for (var i = 0; i < ZDK.mapWidth * ZDK.mapHeight; i++) {
				var pixel:uint = label.readUnsignedShort();
				if (pixel > 0) {
					labelPixels.writeInt(labelColors[pixel % labelColors.length]);
				} else {
					labelPixels.writeInt(0xff000000);
				}
			}
			labelPixels.position = 0;
			labelData.setPixels(new Rectangle(0, 0, ZDK.mapWidth, ZDK.mapHeight), labelPixels);
			} catch (err:Error) {
				debug("failed displaying shit");
				debug(err.toString());
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