package  
{
	import adobe.utils.CustomActions;
	import flash.external.ExternalInterface;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	public class ZDK extends EventDispatcher {
		public var trackedUsers:Array;
		public var trackedHands:Array;

		var activeSessionHand:Number = 0;
		var focusPoint:Vector3D = new Vector3D(0, 0, 0);
		
		public function ZDK() {
			trackedUsers = [];
			trackedHands = [];
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("NewData", NewData);
			}
		}
		
		var usersCount:Number = 0;
		var handsCount:Number = 0;
		
		function NewData(frame: Object) : void {
			UpdateUsers(frame.users);
			UpdateHands(frame.hands);
			if (frame.users.length != usersCount) {
				usersCount = frame.users.length;
				Main.debug('Number of users: ' + usersCount);
			}
			if (frame.hands.length != handsCount) {
				handsCount = frame.hands.length;
				Main.debug('Number of hands: ' + handsCount);
			}
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
				Main.debug(err.toString());
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
				Main.debug(err.toString());
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
	}
}