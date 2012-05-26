package 
{
	import away3d.containers.View3D;
	import away3d.core.base.Object3D;
	import away3d.core.project.MovieClipSpriteProjector;
	import away3d.events.MouseEvent3D;
	import away3d.containers.setvar;
	import away3d.materials.MovieMaterial;
	import digicrafts.album.screen.Screen3D;
	import digicrafts.album.screen.away3d.ScreenA3D;
	import digicrafts.utils.hci.AbstractHCIManager;
	import digicrafts.utils.hci.GeneralHCIManager;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.events.Event;
		import digicrafts.events.ItemEvent;
	import digicrafts.events.HCIManagerEvent;
	import digicrafts.flash.controls.DockMenu3D;
	import digicrafts.events.ResourceLoaderEvent;
	import digicrafts.events.DataSourceEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
	import flash.events.AsyncErrorEvent;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.events.TouchEvent;
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
	import flash.geom.Matrix3D;
	import flash.text.Font;
	import flash.display.StageScaleMode;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import digicrafts.album.DockMenu3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author zigfu
	 */
	public class Main extends Sprite 
	{
		[Embed(source = "../fonts/verdana.ttf", fontFamily = "embeddedFont", embedAsCFF = "false")] public var embeddedFont:Class;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		var dm3d:digicrafts.flash.controls.DockMenu3D;
		var mouseSurface:Sprite;
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			// @#$%^
			stage.align = "TL";
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT; //hack
			dm3d = new digicrafts.flash.controls.DockMenu3D();
			dm3d.addEventListener(DataSourceEvent.BUFFER_COMPLETE , function(e:Object) {
				debug("loaded");
				setTimeout( function():void {
					
					var radians:Number = 270 * (Math.PI / 180.0);
					var offsetWidth:Number = dm3d.width/2.0;
					var offsetHeight:Number =  dm3d.height/2.0;

					// Perform rotation
					var matrix:Matrix = new Matrix();
					matrix.translate(-offsetWidth, -offsetHeight);
					matrix.rotate(radians);
					matrix.translate( +offsetWidth, +offsetHeight);
					matrix.concat(dm3d.transform.matrix);
					//matrix.translate( 100,0);
					dm3d.transform.matrix = matrix;
					//docContainer.rotationZ = 0;
					//dm3d.registrationPoint;
					//rotateSprite(dm3d, 270);
					dm3d.visible = true;
					
					mouseSurface.x = dm3d.x;
					mouseSurface.y = dm3d.y - 2.5*dm3d.height;
					mouseSurface.width = dm3d.width;// dm3d.width;
					mouseSurface.height = dm3d.height;// dm3d.height;
					mouseSurface.graphics.clear();
					mouseSurface.graphics.lineStyle();
					mouseSurface.graphics.beginFill(0);
					mouseSurface.graphics.drawRect(0, 0, dm3d.width, dm3d.height);
					mouseSurface.graphics.endFill();
					//var e:MouseEvent3D = new MouseEvent3D();
					var hciCrap:AbstractHCIManager = dm3d.hciManager;
					//var forwardEvent = function(ev:MouseEvent) {
					//	var es:MouseEvent = new MouseEvent(ev.type, true, false, ev.localX, ev.localY);
					//	dm3d.dispatchEvent(es);
					//	};
					//mouseSurface.addEventListener(MouseEvent.MOUSE_OVER, forwardEvent);
					//mouseSurface.addEventListener(MouseEvent.MOUSE_OUT, forwardEvent);
					//mouseSurface.addEventListener(MouseEvent.MOUSE_MOVE, forwardEvent);
					//mouseSurface.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
					//	var es:HCIManagerEvent = new HCIManagerEvent(HCIManagerEvent.MOVE, e.localX, 0);
					//	hciCrap.dispatchEvent(es);
					//});
					setTimeout(doCrap, 500);
					
				}, 200);
			});
			//dm3d.hciManager = new MyHci();
			dm3d.load("media/menu.xml");
			dm3d.x = 580;
			dm3d.y = 380;
			dm3d.mask = null;
			dm3d.itemWidth = 52;
			dm3d.itemHeight = 52;
			addChild(dm3d);
			
			var format:TextFormat = new TextFormat("embeddedFont");
			format.color = 0xFFFFFF;
			format.size = 32;
			format.bold = false;
			format.align = TextFormatAlign.CENTER;
			
			//dm3d.defaultTooltipFormat.;
			//dm3d.tooltip.label.setTextFormat(format);
			dm3d.tooltip.label = new TextField();
			//dm3d.tooltip.label.embedFonts = true;
			dm3d.tooltip.font = "embeddedFont";
			dm3d.tooltip.textFormat = format;
			dm3d.tooltip.label.setTextFormat(format);
			dm3d.tooltip.label.defaultTextFormat = format;
			dm3d.tooltip.addChild(dm3d.tooltip.label);
			//dm3d.tooltip.label.antiAliasType = AntiAliasType.ADVANCED;
			//dm3d.tooltip.label.embedFonts = true;
			dm3d.visible = false;
			//for (var i in dm3d) { debug(i); debug(dm3d[i]); }
			//debug("fasdfasdf");
					
			dm3d.addEventListener(HCIManagerEvent.TOUCH_DOWN, function(e:Object) {
				//debug("down " + e.localX);
			});
			
			dm3d.addEventListener(HCIManagerEvent.TOUCH_UP, function(e:Object) {
				//debug("up " + e.localX);
			});
			
			dm3d.addEventListener(HCIManagerEvent.MOVE, function(e:Object) {
				//debug("move " + e.localX);
				//debug(e.target.name);
			});
			
			dm3d.addEventListener(Event.MOUSE_LEAVE, function(e:Object) {
				//debug("mouse leave");
			});
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
				//rotateSprite(dm3d, 270);
				//dm3d.visible = true;
				dm3d.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER, true, false, 0.5 * dm3d.width, 0.2 * dm3d.height, dm3d));
			});

			mouseSurface = new Sprite();
			mouseSurface.x = 0;
			mouseSurface.y = 0;
			mouseSurface.width = 100;// dm3d.width;
			mouseSurface.height = 200;// dm3d.height;
			mouseSurface.graphics.lineStyle();
			mouseSurface.graphics.beginFill(0);
			mouseSurface.graphics.drawRect(0, 0, 100, 200);
			mouseSurface.graphics.endFill();
			mouseSurface.width = 100;// dm3d.width;
			mouseSurface.height = 200;// dm3d.height;
			addChild(mouseSurface);
			
		}
		var v:View3D;
		public function doCrap()
		{
			var blah2:digicrafts.album.DockMenu3D = dm3d.getChildAt(0) as digicrafts.album.DockMenu3D;
			var screen:Screen3D = blah2.getChildAt(0) as Screen3D;
			var view:View3D = screen.getChildAt(0) as View3D;
			v = view;
			
			/*var touchCrap:Function = function(outEvent:String) {return function(ev:MouseEvent) {
				var e:TouchEvent = new TouchEvent(outEvent, true, false, 1, true, ev.localX, ev.localY, 5, 5);
				dm3d.dispatchEvent(e);
			}
			};
			mouseSurface.addEventListener(MouseEvent.MOUSE_OVER, touchCrap(TouchEvent.TOUCH_BEGIN));
			mouseSurface.addEventListener(MouseEvent.MOUSE_OUT, touchCrap(TouchEvent.TOUCH_END));
			mouseSurface.addEventListener(MouseEvent.MOUSE_MOVE, touchCrap(TouchEvent.TOUCH_MOVE));*/
			
			var m3dCrap:Function = function(outEvent:String) { return function(ev:MouseEvent) {
				//view._mouseIsOverView = true;
				setvar.setMouseOver(view);
				view.fireMouseEvent(outEvent, ev.localX*2, ev.localY);
			}
			};
			mouseSurface.addEventListener(MouseEvent.MOUSE_OVER, function(ev:MouseEvent) {
				//view._mouseIsOverView = true;
				//setvar.setMouseOver(view);
				view.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
				i = -dm3d.width/3;
				view.fireMouseEvent(MouseEvent3D.MOUSE_OVER, -171, 13/*ev.localY*/);
			});
			mouseSurface.addEventListener(MouseEvent.MOUSE_OUT, m3dCrap(MouseEvent3D.MOUSE_OUT));
			var i:Number = 0;
			mouseSurface.addEventListener(MouseEvent.MOUSE_MOVE, function(ev:MouseEvent) {
				i++;
				//view.fireMouseEvent(MouseEvent3D.MOUSE_MOVE, i, 7/*ev.localY*/);
				view.fireMouseEvent(MouseEvent3D.MOUSE_MOVE, -171, 13/*ev.localY*/);
				//dummy();
			});
			view._screenClipping.maxX += 100;
			
			view.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
				debug(view.mouseX + ", " + view.mouseY);
			});
			stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
				dummy2();
			});
		}
		function dummy() {
			debug("blah");
		}
		function dummy2() {
			//debug("halb");
			v.findHit(v.session, -171, 13);
			var evt:MouseEvent3D = v.getMouseEvent(MouseEvent3D.MOUSE_OVER);
			var blah2:digicrafts.album.DockMenu3D = dm3d.getChildAt(0) as digicrafts.album.DockMenu3D;
			var screen:Screen3D = blah2.getChildAt(0) as ScreenA3D;
			//(screen.container.raw as Object3D).dispatchEvent(evt);
			var mat:MovieMaterial = evt.material as MovieMaterial;
			if (mat != null) {
				var btn:SimpleButton = (mat.movie as MovieClip).getChildAt(0) as SimpleButton;
				btn.upState = btn.overState;
				(mat.movie as MovieClip).dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
			}
			//(evt.object as IEventDispatcher).dispatchEvent(evt);
		}
		
		
		public static function debug(text):void {
            trace(text);
			if (ExternalInterface.available) {
           		ExternalInterface.call("console.log", text);
			}
    	}
	}
	
}