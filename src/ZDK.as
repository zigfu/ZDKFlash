package  
{
	import flash.external.ExternalInterface;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	public class ZDK extends EventDispatcher {
		public var trackedUsers:Array;

		public function ZDK() {
			trackedUsers = [];
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("NewData", NewData);
			}
		}
		
		var usersCount:Number = 0;
		
		function NewData(frame: Object) : void {
			UpdateUsers(frame.users);
			if (frame.users.length != usersCount) {
				usersCount = frame.users.length;
				Main.debug('Number of users: ' + usersCount);
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
		
		function isUserTracked(userid) {
			return (typeof(this.trackedUsers[userid]) != 'undefined');
		}
		
		function getItemById(coll:Array, id) {
			for (var item in coll) {
				if (coll[item].id == id) return item;
			}
			return undefined;
		}
	}
}