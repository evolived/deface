/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector.classifier {
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	/**
	* Both integral image and squared integral image + utility functions and properties.
	* Integral image is described in Viola and Jones.  It's basically an array corresponding to pixels in which each value is the sum of all
	* pixels up and to the left of the array position, inclusive.
	* Squared integral image is similar, but with squared pixel values
	* Also has a tilted sum array, in which the values are the sum of all pixels in the image above and to the left if the image were rotated 45 degrees.
	*/
	public class IntegralImage {
		
		private static var floor:Function = Math.floor;
		private static var bwmat:Array = [0, 0, 0, 0, 0,
										0, 0, 0, 0, 0,
										.59, .3, .11, 0, 0,
										0, 0, 0, 0, 0];

		private static var bwfilter:ColorMatrixFilter = new ColorMatrixFilter(bwmat);
		
		/**
		 * Array (width by height) of Number.  Each entry is the sum of all pixels above and left of pixel at that index, inclusive
		 */
		public var sum:Array; //of Number;
		/**
		 * Array (width by height) of Number.  Each entry is the sum of all pixels (squared) above and left of pixel at that index, inclusive
		 */
		public var sqsum:Array; //of Number;
		/**
		 * Array (width by height) of Number.  Each entry is the sum of all pixels above and left (if the image was rotated 45 degrees) of pixel at that index, inclusive
		 */
		public var tiltsum:Array; //of Number;
		
		/**
		 * width in pixels.  Actually width of input BitmapData + 1 for padding zeros
		 */
		public var width:int;
		/**
		 * height in pixels.  Actually height of input BitmapData + 1 for padding zeros
		 */
		public var height:int;
		
		/**
		 * Construct an IntegralImage from a BitmapData
		 * @param	bd
		 */
		public function IntegralImage(bd:BitmapData) {
			width = bd.width+1;
			height = bd.height+1;
			sum = new Array(width*height);
			sqsum = new Array(width * height);
			tiltsum = new Array((width+1)*(height+1));
			var padded:BitmapData = new BitmapData(bd.width + 1, bd.height + 1, false, 0x00000000 );
			padded.copyPixels(bd, bd.rect, new Point(1,1), null, null, false);
			initFromBitmapData(padded); //don't molest input bitmap.
			
		}
		
		//calculates sums
		private function initFromBitmapData(bd:BitmapData):void {
			//trace("initializing integral image");
			var startTime:int = getTimer();
			// Create the first row of the integral image
			var i_m:Array = new Array(width * height);
			//bwmat takes argb image to grayscale, and stores the result in the blue channel because it's the least significant bits.
			//for some reason, alpha does NOT go to 0, so we do that in the copy to i_m.
			bd.applyFilter(bd, bd.rect, new Point(0, 0), bwfilter);
			var ba:ByteArray = bd.getPixels(bd.rect);
			ba.position = 0;
			sum[0] = 0;
			sqsum[0] = 0;
			tiltsum[0] = 0;
			for (var i:int = 0; i < width * height; i++) {
				i_m[i] = (ba.readUnsignedInt() & 0x000000ff) / 255;
				//i_m[i] = (ba.readUnsignedByte() * 0 + ba.readUnsignedByte() + ba.readUnsignedByte() + ba.readUnsignedByte()) / 765;
				//sum[i] = 0; //i_m[i];
				//sqsum[i] = 0;//i_m[i]*i_m[i];
			}
			
			for (var x:int = 1; x < width; x++)
			{
				sum[x] = sum[x - 1] + i_m[x];
				sqsum[x] = sqsum[x - 1] + i_m[x] * i_m[x];
				tiltsum[x] = 0; //dunno.
			}
    
			// Compute each other row/column
			var r:Number;
			var rs:Number;
			var Y:int = width;
			var YY:int = 0;
			for (var y:int = 1; y < height; y++, Y+=width, YY+=width)
			{
				// Keep track of the row sum
				r = 0;
				rs = 0;
        
				for (x = 0; x < width; x++)
				{
					r += i_m[Y + x];
					rs += i_m[Y + x]*i_m[Y + x];
					sum[Y + x] = sum[YY + x] + r;
					sqsum[Y + x] = sqsum[YY + x] + rs;
					tiltsum[Y+x] = getTiltSumXY(tiltsum, x-1, y-1) + getTiltSumXY(tiltsum, x+1, y-1) 
						- getTiltSumXY(tiltsum, x, y - 2) + i_m[Y+x] + i_m[Y-width+x];
				}
			}
			//FlashConnect.trace("initialized integral image took:"+(getTimer() - startTime));

		}
		
		/**
		 * utility function to get tilted sum array.  Tests for array bounds and returns safe 0 values.
		 * @param	tiltarr - tilted sum array
		 * @param	x - int pixel location x
		 * @param	y - int pixel location y
		 * @return
		 */
		private function getTiltSumXY(tiltarr:Array, x:int, y:int):Number{
			if (x < 0){
				return 0;
			}
			if (y < 0){
				return 0;
			}
			return tiltarr[y*width+x];
			
		}
		
		/**
		 * Gets sum of pixels in r.  Uses only 4 Array lookups and a few operations for index calculation
		 * @param	r rect in which to get sum
		 * @return sum of pixel values in r
		 */
		public function getRectSum(r:Rectangle):Number {
			var toreturn:Number = sum[((r.y + r.height) * width) + r.x + r.width] - sum[(r.y * width) + r.x + r.width] - sum[(r.y + r.height) * width + r.x] + sum[(r.y * width) + r.x]  ;
			/*
			if (isNaN(toreturn)) {
				throw new Error("nan sum generated for rect: " + r);
			}
			*/
			return toreturn;
		}
		
		
		/**
		 * Gets sum of pixels in r from tilted image.
		 * @param	r unrotated rect as defined in HaarRect
		 * @return sum from tilted sum of the input rectangle rotated 45 degrees
		 */
		public function getTiltRectSum(r:Rectangle):Number {
			
			var y:int = r.y;
			var x:int = r.x;
			var w:int = r.width;
			var h:int = r.height;
			
			var a:Number = tiltsum[(y + w) * width + x + w] ;
			var b:Number = tiltsum[(y + h) * width + x - h] ;
			var c:Number = tiltsum[y * width + x] ;
			var d:Number = tiltsum[(y+w+h)*width + x + w -h];
			var toreturn:Number = c + d - a - b; //a + b - c - d;
			/*
			if (isNaN(toreturn)) {
				throw new Error("nan sum generated for tilt rect: " +r+" "+a+" "+b+" " +c+" "+d);
			}
			*/
			return toreturn;
		}
		
		/**
		 * calculates sum of squared pixel values in rectangle.  Used for normalization
		 * @param	r rectangle on which to calculate squared sum
		 * @return sum of squared pixel values in r
		 */
		public function getRectSqSum(r:Rectangle):Number {
			var a:Number = ((r.y + r.height) * width) + r.x + r.width;
			var b:Number = (r.y * width) + r.x + r.width;
			var c:Number = (r.y + r.height) * width + r.x;
			var d:Number = sqsum[(r.y * width) + r.x];
			var toreturn:Number = sqsum[((r.y + r.height) * width) + r.x + r.width] - sqsum[(r.y * width) + r.x + r.width] - sqsum[(r.y + r.height) * width + r.x] + sqsum[(r.y * width) + r.x]  ;
			/*
			if (isNaN(toreturn)) {
				throw new Error("nan sqsum generated for rect: " + r +" a:" + a + " b:" + b + " c:" + c + " d:" + d + " sq[a]:"+sqsum[a]+" sq[b]:"+sqsum[b]+" sq[c]:"+sqsum[c]+" sq[d]:"+sqsum[d]+" sq.length:"+sqsum.length);
			}
			*/
			return toreturn;

		}
		
		/**
		 * gets a string representation.   Very verbose for large images.
		 * @return String 
		 */
		public function toString():String {
			var toreturn:String = "sum=\n";
			var sqstring:String = "sqsum=\n"
			for (var i:int = 0; i < height; i++) {
				toreturn += "[";
				sqstring += "[";
				for (var j:int = 0; j < width; j++) {
					toreturn += sum[i * width + j] + " ";
					sqstring += sqsum[i * width + j] + " ";
				}
				toreturn += "]\n";
				sqstring += "]\n";
			}
			toreturn += sqstring;
			return toreturn;
		}

	}
	
}
