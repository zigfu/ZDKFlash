package  
{
	import flash.events.EventDispatcher;
	
	public class PushDetector extends EventDispatcher
	{
		
		public var size:Number = 160;
		public var driftAmount:Number = 15;

		// these should all be public getters private setters
		public var pushPosition:Array = [0, 0, 0];
		public var pushProgress:Number = 0;
		public var pushTime:Number = 0;
		public var isPushed:Boolean = false;
		
		var fader:Fader;
		
		public function PushDetector() 
		{
			fader = new Fader(Fader.ORIENTATION_Z, size);
			fader.flip = true; // positive Z is backwards by default, so flip it
			fader.initialValue = 0.2;
			fader.autoMoveToContain = true;
			fader.driftAmount = driftAmount;
		}
		
		function onsessionstart(focusPosition) {
			fader.onsessionstart(focusPosition);
		}

		function onsessionupdate(position) {
			fader.moveToContain(position);
			fader.onsessionupdate(position);
			pushProgress = fader.value;
			
			if (!isPushed) {
				if (1.0 == pushProgress) {
					isPushed = true;
					pushTime = (new Date()).getTime();
					pushPosition = position;
					fader.driftAmount = 0; // stop drifting when pushed
					dispatchEvent(new PushDetectorEvent(PushDetectorEvent.PUSH, this));
				}
			} else {
				if (pushProgress < 0.5) {
					release();
				}
			}
		}

		function release() {
			if (!isPushed) return;
			isPushed = false;
			fader.driftAmount = driftAmount;
			dispatchEvent(new PushDetectorEvent(PushDetectorEvent.RELEASE, this));
			if (isClick()) {
				dispatchEvent(new PushDetectorEvent(PushDetectorEvent.CLICK, this));
			}		
		}
		
		function onsessionend() {
			fader.onsessionend();
			if (isPushed) {
				isPushed = false;
				dispatchEvent(new PushDetectorEvent(PushDetectorEvent.RELEASE, this));
			}
		}

		function isClick() {
			var delta = (new Date()).getTime() - pushTime;
			return (delta < 1000);
		}
	}
}