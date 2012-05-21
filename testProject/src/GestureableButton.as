package  
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextField;
	import flash.display.Sprite;
	import flash.text.AntiAliasType;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import flash.utils.Timer;
	import flash.filters.GradientBevelFilter;
	import flash.filters.BevelFilter;

	
	class GestureableButton extends Sprite {
		var idleState:Shape;
		var hoverState:Shape;
		var activeState:Shape;
		var button:SimpleButton;
		var label:TextField;
		var hoverVisualizer:Shape;

		var video:String = "";
		var Caption:String = "";
		var selectCB:Function;
		
		var steadyTimer:Timer;
		var startTime:Number;
		var TIMER_TICK_COUNT:Number = 60 * 1.5; // 60 FPS * time in seconds
		
		//[Embed(source = "../fonts/verdana.ttf", fontFamily = "embeddedFont", embedAsCFF = "false")] private var embeddedFont:Class;
		//[Embed(source = "../fonts/verdana.ttf", fontFamily = "embeddedFont", embedAsCFF = "false")] private var embeddedFont:Class;
		[Embed(source = "../fonts/verdanab.ttf",fontFamily="embeddedFont",fontWeight="bold",embedAsCFF="false")] private var embeddedBoldFont:Class;
	
		public function GestureableButton(caption:String, width:Number, height:Number, CB:Function) {
			selectCB = CB;
			Caption = caption;
			steadyTimer = new Timer(1.0 / 60.0, TIMER_TICK_COUNT);
			steadyTimer.addEventListener(TimerEvent.TIMER, function(te:TimerEvent) {
				// the range of values we call visualize is -0.3 to 1
				// all values <= 0 will result in an empty progress bar
				// essentially giving us a steady timer
				visualize(1.3 *(steadyTimer.currentCount / TIMER_TICK_COUNT) - 0.3);
			});
			
			steadyTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(te:TimerEvent) {
				selectCB();
			});
		
			// 1. Button (all states)
			
			idleState = new Shape();
			//idleState.graphics.lineStyle(3,0xff1010);
			idleState.graphics.beginFill(0x59D5F1, 1);
			idleState.graphics.drawRoundRect(0, 0, width, height, 40);
			idleState.filters = [new BevelFilter(1)];
			idleState.graphics.endFill();

			hoverState = new Shape();
			hoverState.graphics.lineStyle(1,0x061AD3);
			hoverState.graphics.beginFill(0x59D5F1, 0.5);
			hoverState.graphics.drawRoundRect(0, 0, width, height, 40);
			hoverState.filters = [new BevelFilter(1)];
			hoverState.graphics.endFill();

			activeState = new Shape();
			activeState.graphics.lineStyle(1,0x061AD3);
			activeState.graphics.beginFill(0x59D5F1, 1);
			activeState.filters = [new BevelFilter(1)];
			activeState.graphics.drawRoundRect(0,0,width,height,40);
			activeState.graphics.endFill();
			
			button = new SimpleButton();
			
			// 2. Hover visualization

			// mask for background
			var overlayMask:Shape = new Shape();
			overlayMask.graphics.lineStyle(3,0xff1010);
			overlayMask.graphics.beginFill(0xFF0000, 0.3);
			overlayMask.graphics.drawRoundRect(0,0,width,height,40);
			overlayMask.graphics.endFill();
			
			// background
			hoverVisualizer = new Shape();
			var mat:Matrix=new Matrix();
			var colors=[0x59D5F1,0x59D5F1,0x59D5F1,0x59D5F1];
			var alphas=[1,1,0,0];
			var ratios=[0,124,128,255];
			mat.createGradientBox(width * 2, height);
			hoverVisualizer.graphics.lineStyle();
			hoverVisualizer.graphics.beginGradientFill(GradientType.LINEAR,colors,alphas,ratios,mat);
			hoverVisualizer.graphics.drawRect(0,0,width*2,height);
			hoverVisualizer.graphics.endFill();
			hoverVisualizer.mask = overlayMask;
			hoverVisualizer.x = -width;
			hoverVisualizer.cacheAsBitmap = true;
			
			// 3. Label
			
			var format:TextFormat = new TextFormat("embeddedFont");
			format.color = 0xFFFFFF;
			format.size = 22;
			format.bold = false;
			format.align = TextFormatAlign.CENTER;
			
			label = new TextField();
			label.embedFonts = true;
			label.width = width;
			label.height = height;
			label.selectable = false;
			label.mouseEnabled = false;
			label.antiAliasType = AntiAliasType.ADVANCED;
			label.defaultTextFormat = format;
			label.filters = [new DropShadowFilter(1)];
			label.text = caption;
			label.y = (height - label.textHeight) * 0.5;
			
			setIdle();
			
			// compose
			addChild(button);
			addChild(hoverVisualizer);
			addChild(overlayMask);
			addChild(label);
		}
		
		public function setIdle() {
			button.upState = idleState;
			button.overState = hoverState;
			button.downState = activeState;
			button.hitTestState = idleState;
			hoverVisualizer.visible = false;
			hoverVisualizer.x = -hoverVisualizer.width;
			steadyTimer.stop();
			label.textColor = 0xFFFFFF;
		}
		
		public function setHover() {
			button.upState = button.downState = button.overState = button.hitTestState = hoverState;
			label.textColor = 0xFFFFFF;
			steadyTimer.reset();
			steadyTimer.start();
		}
		
		public function setActive() {
			button.upState = button.downState = button.overState = button.hitTestState = activeState;
			steadyTimer.stop();
			label.textColor = 0x061AD3;
			hoverVisualizer.visible = false;
			hoverVisualizer.x = -hoverVisualizer.width;
		}
		
		public function visualize(val:Number) {
			hoverVisualizer.visible = true;
			hoverVisualizer.x = (val - 1) * width / 2;
		}
	}
}