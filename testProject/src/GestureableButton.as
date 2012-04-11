package  
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextField;
	import flash.display.Sprite;
	
	class GestureableButton extends Sprite {
		var idleState:Shape;
		var hoverState:Shape;
		var activeState:Shape;
		var button:SimpleButton;
		var label:TextField;
		
		public function GestureableButton(caption:String, width:Number, height:Number) {
			idleState = new Shape();
			idleState.graphics.lineStyle(3,0xff1010);
			idleState.graphics.beginFill(0xFF0000, 0.3);
			idleState.graphics.drawRoundRect(0,0,width,height,20);
			idleState.graphics.endFill();

			hoverState = new Shape();
			hoverState.graphics.lineStyle(3,0xff5555);
			hoverState.graphics.beginFill(0xFF0000, 0.8);
			hoverState.graphics.drawRoundRect(0,0,width,height,20);
			hoverState.graphics.endFill();

			activeState = new Shape();
			activeState.graphics.lineStyle(3,0x44ff44);
			activeState.graphics.beginFill(0x00FF00, 0.8);
			activeState.graphics.drawRoundRect(0,0,width,height,20);
			activeState.graphics.endFill();
			
			button = new SimpleButton();
			setIdle();
			
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.color = 0x000000;
			format.size = 28;
			format.bold = false;
			format.align = TextFormatAlign.CENTER;
			
			label = new TextField();
			label.width = width;
			label.height = height;
			label.selectable = false;
			label.mouseEnabled = false;
			label.defaultTextFormat = format;
			label.text = caption;
			label.y = (height - 28) / 2;
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