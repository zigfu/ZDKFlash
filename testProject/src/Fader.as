package  
{
	import flash.events.EventDispatcher;

	public class Fader extends EventDispatcher
	{
		var isEdge = false;
		
		public static const ORIENTATION_X:Number = 0;
		public static const ORIENTATION_Y:Number = 1;
		public static const ORIENTATION_Z:Number = 2;
		
		public var itemsCount:Number = 1;
		public var value:Number;
		public var hoverItem:Number;
		public var hysteresis:Number = 0.1;
		public var initialValue:Number = 0.5;
		public var flip:Boolean = false;
		public var driftAmount:Number = 0;
		public var autoMoveToContain:Boolean = false;
		public var size:Number = 250;
		public var orientation:Number = ORIENTATION_X;

		public var center:Array = [0, 0, 0];

		public function Fader(ori, sz) {
			if (undefined !== orientation) orientation = ori;
			if (undefined !== sz) size = sz;
		}
		
		function onsessionstart(focusPosition) {
			moveTo(focusPosition, initialValue);
			value = initialValue;
			hoverItem = Math.floor(itemsCount * value);
			dispatchEvent(new FaderEvent(FaderEvent.HOVERSTART, this));
		}

		function onsessionupdate(position) {
			updatePosition(position);
		}

		function onsessionend() {
			dispatchEvent(new FaderEvent(FaderEvent.HOVERSTOP, this));
			hoverItem = -1;
		}

		function clamp(val, min, max) {
			if (val > max) return max;
			if (val < min) return min;
			return val;
		}
		
		function updatePosition(position) {
			if (autoMoveToContain) {
				moveToContain(position);
			}

			var distanceFromCenter = position[orientation] - center[orientation];
			var ret = (distanceFromCenter / size) + 0.5;
			ret = clamp(ret, 0, 1);
			if (flip) ret = 1 - ret;
			updateValue(ret);

			if (driftAmount != 0) {
				var delta = initialValue - value;
				moveTo(position, value + (delta * 0.05));
			}
		}

		function updateValue(val) {
			var newSelected = hoverItem;
			var minValue = (hoverItem * (1 / itemsCount)) - hysteresis;
			var maxValue = (hoverItem + 1) * (1 / itemsCount) + hysteresis;
			
			value = val;
			dispatchEvent(new FaderEvent(FaderEvent.VALUECHANGE, this));
			
			var isThisFrameEdge = (value == 0) || (value == 1);
			if (!isEdge && isThisFrameEdge) {
				dispatchEvent(new FaderEvent(FaderEvent.EDGE, this));
			}
			isEdge = isThisFrameEdge;

			if (value > maxValue) {
				newSelected++;
			}
			if (value < minValue) {
				newSelected--;
			}
			
			if (newSelected != hoverItem) {
				dispatchEvent(new FaderEvent(FaderEvent.HOVERSTOP, this));
				hoverItem = newSelected;
				dispatchEvent(new FaderEvent(FaderEvent.HOVERSTART, this));
			}		
		}
	
		function moveTo(position, val) {
			if (flip) val = 1 - val;
			center[orientation] = position[orientation] + ((0.5 - val) * size);
		}
		
		function moveToContain(position) {
			var distanceFromCenter = position[orientation] - center[orientation];
			if (distanceFromCenter > size / 2) {
				center[orientation] += distanceFromCenter - (size / 2);
			} else if (distanceFromCenter < size / -2) {
				center[orientation] += distanceFromCenter + (size / 2);
			}
		}
	}
}