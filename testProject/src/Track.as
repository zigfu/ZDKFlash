package  
{
	import adobe.utils.CustomActions;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.sendToURL;
	import com.adobe.serialization.json.JSON;
	
	public class Track {
		static function track(e:String, o:Object = null ) {
			o = o || new Object();
			o['event'] = e;
			var req:URLRequest = new URLRequest("http://localhost:1337/log");
			req.method = "POST";
			req.requestHeaders.push( new URLRequestHeader("Content-type", "application/json" ));
			req.contentType = "application/json";
			req.data = JSON.encode(o);
			sendToURL(req);
		}
	}
}