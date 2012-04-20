package  
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextField;
	import flash.display.Sprite;
	import flash.text.AntiAliasType;

	
	class GestureableButton extends Sprite {
		var idleState:Shape;
		var hoverState:Shape;
		var activeState:Shape;
		var button:SimpleButton;
		var label:TextField;

		public var video:String = "";
		
		[Embed(source = "../fonts/verdana.ttf",fontFamily="embeddedFont",embedAsCFF="false")] private var embeddedFont:Class;
	
		public function GestureableButton(caption:String, width:Number, height:Number) {
			idleState = new Shape();
			idleState.graphics.lineStyle(3,0xff1010);
			idleState.graphics.beginFill(0xFF0000, 0.3);
			idleState.graphics.drawRoundRect(0,0,width,height,40);
			idleState.graphics.endFill();

			hoverState = new Shape();
			hoverState.graphics.lineStyle(3,0xff5555);
			hoverState.graphics.beginFill(0xFF0000, 0.8);
			hoverState.graphics.drawRoundRect(0,0,width,height,40);
			hoverState.graphics.endFill();

			activeState = new Shape();
			activeState.graphics.lineStyle(3,0x44ff44);
			activeState.graphics.beginFill(0x00FF00, 0.8);
			activeState.graphics.drawRoundRect(0,0,width,height,40);
			activeState.graphics.endFill();
			
			button = new SimpleButton();
			setIdle();
			
			var format:TextFormat = new TextFormat("embeddedFont");
			format.color = 0xFFFFFF;
			format.size = 17;
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
			label.text = caption;
			label.y = (height - label.textHeight) * 0.5;
			addChild(button);
			addChild(label);
		}
		
		public function setIdle() {
			trace("Set idle");
			button.upState = idleState;
			button.overState = hoverState;
			button.downState = activeState;
			button.hitTestState = idleState;
		}
		
		public function setHover() {
			trace("Set hover");
			button.upState = button.downState = button.overState = button.hitTestState = hoverState;
		}
		
		public function setActive() {
			trace("Set active");
			button.upState = button.downState = button.overState = button.hitTestState = activeState;
		}
	}
}