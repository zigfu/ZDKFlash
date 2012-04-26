package  
{
	import adobe.utils.CustomActions;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.sendToURL;
	import com.adobe.serialization.json.JSON;
	
	public class Track {
		static function track(e:String, o:Object = null, timestamp:Number = 0) {
			o = o || new Object();
			timestamp = timestamp || (+new Date().time);
			o['event'] = e;
			o['timestamp'] = timestamp;
			var req:URLRequest = new URLRequest("http://localhost:1337/log");
			req.method = "POST";
			req.requestHeaders.push( new URLRequestHeader("Content-type", "application/json" ));
			req.contentType = "application/json";
			req.data = JSON.encode(o);
			sendToURL(req);
		}
	}
}