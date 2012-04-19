package  
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.TextFormatAlign;
	
	public class Overlay extends Sprite {	
		var spriteFrame:Shape;
		var spriteButtons:Sprite;
		var spriteSessionPrompt:Sprite;
		
		var activeButton:GestureableButton;
		var buttons:Array;
		
		var buttonClickCB;
		
		public function Overlay(width:Number, height:Number, buttonsJson:Array, buttonClickCallback) {
			buttonClickCB = buttonClickCallback;
			
			// create frame
			spriteFrame = new Shape();
			spriteFrame.graphics.lineStyle(3,0xff1010);
			spriteFrame.graphics.beginFill(0xFF0000, 0.3);
			spriteFrame.graphics.drawRoundRect(0,0,width,height,20);
			spriteFrame.graphics.endFill();
			
			// create buttons
			spriteButtons = new Sprite();
			var padding = 15;
			var buttonWidth = (width - ((buttonsJson.length + 1) * padding)) / buttonsJson.length;
			var buttonHeight = height - (padding * 2);
			var currTop = padding;
			var currLeft = padding;
			buttons = [];
			for each (var currentButton:Object in buttonsJson) {
				var button:GestureableButton = new GestureableButton(currentButton.label, buttonWidth, buttonHeight);
				button.x = currLeft;
				button.y = currTop;
				button.video = currentButton.video;
				button.addEventListener(MouseEvent.CLICK, (function(curr:Object, b:GestureableButton) { return function() {
					activate(b);
				};})(currentButton, button));
				spriteButtons.addChild(button);
				buttons.push(button);
				currLeft += buttonWidth + padding;
			}
			
			// create session prompt
			var tf:TextFormat = new TextFormat("embeddedFont");
			tf.size = 50;
			tf.bold = false;
			tf.align = TextFormatAlign.CENTER;
			tf.color = 0xFFFFFF;
			var lbl:TextField = new TextField();
			lbl.text = "Raise hand for more info";
			lbl.embedFonts = true;
			lbl.antiAliasType = AntiAliasType.ADVANCED;
			lbl.defaultTextFormat = tf;
			lbl.setTextFormat(tf);
			lbl.width = width;
			lbl.height = height;
			lbl.selectable = false;
			lbl.mouseEnabled = false;
			lbl.x = 0;
			lbl.y = 40;
			spriteSessionPrompt = new Sprite();
			spriteSessionPrompt.addChild(lbl);

			hide();
			
			// add all overlay objects to parent
			addChild(spriteFrame);
			addChild(spriteButtons);
			addChild(spriteSessionPrompt);
		}
		
		public function hover(n) {
			if (activeButton != buttons[n]) {
				buttons[n].setHover();
			}
		}
		
		public function unhover(n) {
			if (activeButton != buttons[n]) {
				buttons[n].setIdle();
			}
		}
		
		public function activate(n) {
			deactivate();
			if (typeof(n) == "Number") n = buttons[n];
			activeButton = buttons[n];
			activeButton.setActive();
			buttonClickCB(activeButton.video);
		}
		
		public function deactivate() {
			if (activeButton) {
				activeButton.setIdle();
				activeButton = null;
			}
		}
		
		public function showButtons() {
			spriteFrame.visible = true;
			spriteButtons.visible = true;
			spriteSessionPrompt.visible = false;
		}
		
		public function showSessionPrompt() {
			spriteFrame.visible = true;
			spriteButtons.visible = false;
			spriteSessionPrompt.visible = true;
		}
		
		public function hide() {
			spriteFrame.visible = false;
			spriteButtons.visible = false;
			spriteSessionPrompt.visible = false;
		}
	}
}