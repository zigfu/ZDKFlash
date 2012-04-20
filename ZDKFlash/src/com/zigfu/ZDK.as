package com.zigfu
{
	import adobe.utils.CustomActions;
	import flash.external.ExternalInterface;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class ZDK extends EventDispatcher {
		public var trackedUsers:Array;
		public var trackedHands:Array;

		var activeSessionHand:Number = 0;
		var focusPoint:Vector3D = new Vector3D(0, 0, 0);
		
		public static const mapWidth  : int = 160;
		public static const mapHeight : int = 120;
		public static const maxDepth  : int = 10000;
		public var imageMap:ByteArray;
		public var depthMap:ByteArray;
		public var labelMap:ByteArray;
		
		public var rotateHands:Boolean = true;
		
		public function ZDK() {
			trackedUsers = [];
			trackedHands = [];
			imageMap = new ByteArray();
			imageMap.length = 4 * mapWidth * mapHeight; //32bpp
			depthMap = new ByteArray();
			depthMap.length = 2 * mapWidth * mapHeight; //16bpp
			depthMap.endian = Endian.LITTLE_ENDIAN;
			labelMap = new ByteArray();
			labelMap.endian = Endian.LITTLE_ENDIAN;
			labelMap.length = 2 * mapWidth * mapHeight; //16bpp
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("NewData", NewData);
				ExternalInterface.addCallback("NewImageMap", NewImageMap);
				ExternalInterface.addCallback("NewDepthMap", NewDepthMap);
				ExternalInterface.addCallback("NewLabelMap", NewLabelMap);
			}
		}
		
		public var usersCount:Number = 0;
		public var handsCount:Number = 0;
		
		function NewData(frame: Object) : void {
			try {
				usersCount = frame.users.length;
				UpdateUsers(frame.users);
				if (rotateHands) {
					for (var handid in frame.hands) {
						var hand = frame.hands[handid];
						if (this.isUserTracked(hand.userid)) {
							var rotated:Vector3D = this.rotatePoint(arrayToVector3(hand.position), arrayToVector3(this.trackedUsers[hand.userid].centerofmass));
							hand.position[0] = rotated.x;
							hand.position[1] = rotated.y;
							hand.position[2] = rotated.z;
						}
					}
				}
				UpdateHands(frame.hands);
				if (frame.hands.length != handsCount) {
					handsCount = frame.hands.length;
				}
			} catch (e:Error) {
				debug("Error processing data from plugin:");
				debug(e);
			}
		}
		
		function NewImageMap(data:String):void {
			imageMap.position = 0;
			if (data.length > 0) { 
				// decode to flash-native 0xAARRGGBB format with alpha hard-coded to 0xFF
				Base64.decodeRGBToBGRA(data, imageMap);
			}
			imageMap.position = 0;
		}
		function NewDepthMap(data:String):void {
			depthMap.position = 0;
			if (data.length > 0) {
				// decoded data is little-endian unsigned 16-bit integers
				Base64.decodeInPlace(data, depthMap);
			}
			depthMap.position = 0;
		}
		function NewLabelMap(data:String):void {
			labelMap.position = 0;
			if (data.length > 0) { 
				// decoded data is little-endian unsigned 16-bit integers
				Base64.decodeInPlace(data, labelMap);
			}
			labelMap.position = 0;
		}
		
		function ProcessNewHand(hand) {
			trackedHands[hand.id] = [];
			if (0 == activeSessionHand) {
				activeSessionHand = hand.id;
				focusPoint = arrayToVector3(hand.position);
				this.dispatchEvent(new SessionEvent(SessionEvent.SESSIONSTART, focusPoint, focusPoint));
			}
		}
		
		public function get inSession():Boolean{
			return (0 != activeSessionHand);
		}
		
		function ProcessLostHand(handid) {
			delete trackedHands[handid];
			if (handid == activeSessionHand) {
				activeSessionHand = 0;
				this.dispatchEvent(new SessionEvent(SessionEvent.SESSIONEND, focusPoint, new Vector3D()));
			}
		}
		
		function UpdateUsers(users: Array) : void {
			try {
				var toRemove:Array = [];
				var toAdd:Array = [];
				
				// get rid of old users
				for (var userid in this.trackedUsers) {
					var curruser = this.getItemById(users, userid);
					if (undefined == curruser) {
						toRemove.push(userid);
						delete trackedUsers[userid];
					}
				}
				
				// add new users
				for (var user in users) {
					if (!this.isUserTracked(users[user].id)) {
						trackedUsers[userid] = [];
						toAdd.push(userid);
					}
				}

				// update stuff
				for (user in users) {
					this.trackedUsers[users[user].id] = users[user];
				}
				
				// send found/lost events
				for each (var uid in toRemove) {
					this.dispatchEvent(new UserEvent(UserEvent.USERLOST, uid));
				}
				for each (var uid in toAdd) {
					this.dispatchEvent(new UserEvent(UserEvent.USERFOUND, uid));
				}				

				// frame event
				this.dispatchEvent(new Event("Update"));
			} catch (err:Error) {
				ZDK.debug("ZDK Error: " + err.toString());
			}
		}
		
		function UpdateHands(hands:Array) :void {
			try {
				// get rid of old hands
				for (var handid in this.trackedHands) {
					var currhand = this.getItemById(hands, handid);
					if (undefined == currhand) {
						this.ProcessLostHand(handid);
					}
				}
				
				// add new hands
				for (var hand in hands) {
					if (!this.isHandTracked(hands[hand].id)) {
						this.ProcessNewHand(hands[hand]);
					}
				}

				// update stuff
				for (hand in hands) {
					this.trackedHands[hands[hand].id] = hands[hand];
				}
				
				if (0 != activeSessionHand) {
					var handPoint:Vector3D = arrayToVector3(trackedHands[activeSessionHand].position);
					this.dispatchEvent(new SessionEvent(SessionEvent.SESSIONUPDATE, focusPoint, handPoint));
				}
				
			} catch (err:Error) {
				ZDK.debug("ZDK Error: " + err.toString());
			}
		}
		
		function arrayToVector3(position:Array):Vector3D {
			return new Vector3D(position[0], position[1], position[2]);
		}
		
		function isUserTracked(userid) {
			return (typeof(this.trackedUsers[userid]) != 'undefined');
		}
		
		function isHandTracked(handid) {
			return (typeof(this.trackedHands[handid]) != 'undefined');
		}
		
		function getItemById(coll:Array, id) {
			for (var item in coll) {
				if (coll[item].id == id) return item;
			}
			return undefined;
		}
		
		public static function debug(text):void {
			trace(text);
			if (ExternalInterface.available) {
				ExternalInterface.call("console.log", text);
			}
		}
		
		function rotatePoint(handPos:Vector3D, comPos:Vector3D):Vector3D
		{
			// change the forward vector to be u = (CoM - (0,0,0))
			// instead of (0,0,1)
			var cx:Number = comPos.x;
			var cy:Number = comPos.y;
			var cz:Number = comPos.z;
			
			var len:Number = Math.sqrt(cx*cx + cy*cy + cz*cz);
			// project the vector to XZ plane, so it's actually (cx,0,cz). let's call it v
			// so cos(angle) = v . u / (|u|*|v|)
			var lenProjected:Number = Math.sqrt(cx*cx + cz*cz);
			var cosXrotation:Number = (cx*cx + cz*cz) / (lenProjected * len); // this can be slightly simplified
			var xRot:Number = Math.acos(cosXrotation);
			if (cy < 0) xRot = -xRot; // set the sign which we lose in 
			// now for the angle between v and the (0,0,1) vector for Y-axis rotation
			var cosYrotation:Number = cz / lenProjected;
			var yRot:Number = Math.acos(cosYrotation);
			if (cx > 0) yRot = -yRot;
			var rotation:Matrix3D = new Matrix3D();
			rotation.appendRotation(xRot, Vector3D.X_AXIS);
			rotation.appendRotation(yRot, Vector3D.Y_AXIS);
			return rotation.transformVector(handPos);
		}

	}
}