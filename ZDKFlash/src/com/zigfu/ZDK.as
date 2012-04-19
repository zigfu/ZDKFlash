package com.zigfu
{
	import adobe.utils.CustomActions;
	import flash.external.ExternalInterface;
	import flash.events.EventDispatcher;
	import flash.events.Event;
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
		
		var usersCount:Number = 0;
		var handsCount:Number = 0;
		
		function NewData(frame: Object) : void {
			UpdateUsers(frame.users);
			UpdateHands(frame.hands);
			if (frame.users.length != usersCount) {
				usersCount = frame.users.length;
			}
			if (frame.hands.length != handsCount) {
				handsCount = frame.hands.length;
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
		
		function ProcessNewUser(userid) {
			trackedUsers[userid] = [];
			this.dispatchEvent(new UserEvent(UserEvent.USERFOUND, userid));
		}
		
		function ProcessLostUser(userid) {
			delete trackedUsers[userid];
			this.dispatchEvent(new UserEvent(UserEvent.USERLOST, userid));
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
				// get rid of old users
				for (var userid in this.trackedUsers) {
					var curruser = this.getItemById(users, userid);
					if (undefined == curruser) {
						this.ProcessLostUser(userid);
					}
				}
				
				// add new users
				for (var user in users) {
					if (!this.isUserTracked(users[user].id)) {
						this.ProcessNewUser(users[user].id);
					}
				}

				// update stuff
				for (user in users) {
					this.trackedUsers[users[user].id] = users[user];
				}
				
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

	}
}