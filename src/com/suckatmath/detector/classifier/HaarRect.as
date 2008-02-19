/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector.classifier {
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * A simple class consisting of a Rectangle and a weight.  Rect is relative to original scale of HaarClassifier
	 */
	public class HaarRect {
		/**
		 * Original rectangle, as defined in xml file.  Relative to parent Feature.
		 */
		public var origrect:Rectangle;
		/**
		 * origrect, as scaled to current classifier size
		 */
		public var rect:Rectangle;

		/**
		 * Number by which to multiply pixel sum
		 */
		public var weight:Number; //float
		/**
		 * scaled and translated rectangle to use to get pixel sum from IntegralImage
		 */
		public var operatingRect:Rectangle;
		
		private var floor:Function = Math.floor;
		
		
		/**
		 * basic constructor
		 * @param	x int x pixel location in classifier
		 * @param	y int y pixel location in classifier
		 * @param	w int width in pixels
		 * @param	h int height in pixels
		 * @param	lbs Number weight.
		 */
		public function HaarRect(x:int, y:int, w:int, h:int, lbs:Number) {
			origrect = new Rectangle(x, y, w, h);
			rect = origrect.clone();
			operatingRect = rect.clone();
			weight = lbs;
		}
		
		/**
		 * serialize to xml.  Should be compatible with OpenCV, not guaranteed.
		 * @return String rect as xml
		 */
		public function toXMLString():String {
			var toreturn:String = "<_>" + origrect.x + " " + origrect.y + " " + origrect.width + " " + origrect.height + " " + weight + "</_>";
			return toreturn;
		}
		
		/**
		 * evaluates this rectangle on the image
		 * 
		 * @param	ii IntegralImage to get pixel sums from
		 * @param	r Rectangle window in which to look
		 * @param	tilted Boolean whether this is in a tilted feature
		 * @return Number sum of pixel values in image, multiplied by weight
		 */
		public function evaluateSubImage(ii:IntegralImage, r:Rectangle, tilted:Boolean ):Number {
			operatingRect.x = r.x + rect.x;
			operatingRect.y = r.y + rect.y;
			var sum:Number;
			if (tilted) {
				sum = ii.getTiltRectSum(operatingRect);
			}else {
				sum = ii.getRectSum(operatingRect);
			}
			if (isNaN(sum)) {
				trace("sum of rect: "+operatingRect+" is nan!");
			}
			return sum * weight;
		}
		
		/**
		 * scale to new size described by r
		 * @param	w int original classifier width in pixels
		 * @param	h int original classifier height in pixels
		 * @param	r Rectangle describing search window
		 */
		public function setScale(w:int, h:int, r:Rectangle):void {
			var xscale:Number = r.width/w;
			var yscale:Number = r.height/h;
			rect = new Rectangle(floor(origrect.x * xscale), floor(origrect.y * yscale), floor(origrect.width * xscale), floor(origrect.height * yscale));
			operatingRect = rect.clone();
			
		}
		
	}
	
}
