package  
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author ...
	 */
	public class Base64 {
		private static  const encodeChars:Array =
		['A','B','C','D','E','F','G','H',
		'I','J','K','L','M','N','O','P',
		'Q','R','S','T','U','V','W','X',
		'Y','Z','a','b','c','d','e','f',
		'g','h','i','j','k','l','m','n',
		'o','p','q','r','s','t','u','v',
		'w','x','y','z','0','1','2','3',
		'4','5','6','7','8','9','+','/'];
		private static  const decodeChars:Array =
		[-1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, 62, -1, -1, -1, 63,
		52, 53, 54, 55, 56, 57, 58, 59,
		60, 61, -1, -1, -1, -1, -1, -1,
		-1,  0,  1,  2,  3,  4,  5,  6,
		7,  8,  9, 10, 11, 12, 13, 14,
		15, 16, 17, 18, 19, 20, 21, 22,
		23, 24, 25, -1, -1, -1, -1, -1,
		-1, 26, 27, 28, 29, 30, 31, 32,
		33, 34, 35, 36, 37, 38, 39, 40,
		41, 42, 43, 44, 45, 46, 47, 48,
		49, 50, 51, -1, -1, -1, -1, -1];
		//NOTE: this is naive decoding - we're assuming good data to make things fast
		// and assuming str.length divides by 4
		public static function decodeInPlace(str:String, out:ByteArray):void {
			var c1:int;
			var c2:int;
			var c3:int;
			var c4:int;
			var i:int;
			var len:int;
			len = str.length;
			i = 0;
			while (i < len) {
				c1 = decodeChars[str.charCodeAt(i++) & 0xff];
				c2 = decodeChars[str.charCodeAt(i++) & 0xff];
				out.writeByte((c1 << 2) | ((c2 & 0x30) >> 4));
				c3 = decodeChars[str.charCodeAt(i++) & 0xff];
				out.writeByte(((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2));
				c4 = decodeChars[str.charCodeAt(i++) & 0xff];
				out.writeByte(((c3 & 0x03) << 6) | c4);
			}
		}
		public static function decode(str:String):ByteArray {
			var out:ByteArray;
			out = new ByteArray();
			decodeInPlace(str, out);
			return out;
		}
		public static function decodeRGBToBGRA(str:String, out:ByteArray):void {
			var i:int;
			var len:int;
			len = str.length;
			i = 0;
			var outInt:int;
			while (i < len) {
				outInt = 0xff000000 |
						(decodeChars[str.charCodeAt(i++) & 0xff] << 18) |
						(decodeChars[str.charCodeAt(i++) & 0xff] << 12) |
						(decodeChars[str.charCodeAt(i++) & 0xff] <<  6) |
						decodeChars[str.charCodeAt(i++) & 0xff];
						
				out.writeInt(outInt);
			}
		}

	}

}