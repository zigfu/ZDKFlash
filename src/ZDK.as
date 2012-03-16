package  
{
	import flash.external.ExternalInterface;
	
	public class ZDK 
	{
		public function ZDK() 
		{
			Main.debug('ZDK ctor');
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("NewData", NewData);
			}
		}
		
		var usersCount:Number = 0;
		
		function NewData(frame: Object) : void {
			if (frame.users.length != usersCount) {
				usersCount = frame.users.length;
				Main.debug('Number of users: ' + usersCount);
			}
		}
	}
}