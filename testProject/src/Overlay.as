package  
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.TextFormatAlign;
	import flash.display.GradientType;
	
	public class Overlay extends MovieClip {	
		var spriteFrame:Shape;
		var background:Shape;
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
			
			// background
			background = new Shape();
			var mat:Matrix=new Matrix();
			var colors=[0xFF0000,0xFFFF00,0x00FF00,0x00FFFF,0x0000FF,0xFF00FF,0xFF0000];
			var alphas=[1,1,1,1,1,1,1];
			//255/6=42.5, round off is 42. We want to divide 255 long spectrum
			//into 6 equally spaced pieces to distribute uniformly 7 colors.
			var ratios=[0,42,84,126,168,210,255];
			mat.createGradientBox(width * 2, height);
			//background.width = width * 2;
			background.graphics.lineStyle();
			background.graphics.beginGradientFill(GradientType.LINEAR,colors,alphas,ratios,mat);
			background.graphics.drawRect(0,0,width*2,height);
			background.graphics.endFill();
			background.mask = spriteFrame;
			background.x = -(width / 2);
			background.cacheAsBitmap = true;
			
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

			//hide();
			showSessionPrompt();
			
			// add all overlay objects to parent
			addChild(spriteFrame);
			addChild(background);
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
		
		public function visualizeFader(val:Number) {
			// assumes val is normalized
			background.x = (val - 1) * height/2; // we're using height and not width because the overlay is rotated -90 degrees
		}
		
		public function hide() {
			spriteFrame.visible = false;
			spriteButtons.visible = false;
			spriteSessionPrompt.visible = false;
		}
	}
}