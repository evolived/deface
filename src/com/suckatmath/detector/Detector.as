/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector {
	import com.suckatmath.detector.classifier.HaarClassifier;
	import com.suckatmath.detector.classifier.IntegralImage;
	import flash.display.Bitmap;
	
	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	/**
	 * A Detector applies a HaarClassifier to an Image, getting back an Array of Rectangles representing matching areas of the image.
     */
	public class Detector {
		private var maxDetect:int;

		/**
		 * The classifier to use to determine whether an image area matches.
		 */
		public var classifier:HaarClassifier;
		/**
		 * size of smallest feature to find (in pixels).  
		 * Higher values give faster performance, lower give more thorough.
		 */
		public var minscale:int;
		/**
		 * ratio of classifier height/width
		 */
		public var aspectRatio:Number;
		
		/**
		 * @private
		 */
		protected static var floor:Function = Math.floor;
		/**
		 * @private
		 */
		protected static var max:Function = Math.max;
		
		/**
		 * 
		 * @param	hc  classifier determining feature(s) to recognize
		 * @param	md  maximum number of matching rectangles to return - May not correspond to actual distinct features as same feature
		 * can be detected at multiple enclosing rectangles
		 * @param	minscale minimum of smallest dimension of classifier.
		 */
		public function Detector(hc:HaarClassifier = null, md:int = 1, minscale:int = 20 ):void {
			classifier = hc;
			this.aspectRatio = hc.height / hc.width;
			this.maxDetect = md;
			this.minscale = minscale;
		}
		
		/**
		 * setter for maxDetect.  Set to -1 for unlimited.
		 * @param	md
		 */
		public function setMaxDetect(md:int):void {
			this.maxDetect = md;
		}
		
		/**
		 * scan classifier across bd at DECREASING scales, looking for objects.
		 * Decreasing scales allow bigger (probably closer) objects to have priority.
		 * Will find at most maxDetect objects.  If maxDetect == -1, find ALL.
		 * 
		 * @param bd BitmapData on which to search
		 * @param boundaryRect a rectangle describing the area of the image in which to look.  If null, entire image is used
		 * 
		 * @return Array of Rectangles describing areas where objects were found.
		 */
		public function detect(bd:BitmapData, boundaryRect:Rectangle = null):Array {
			var ii:IntegralImage = new IntegralImage(bd); //todo, make this cacheable for multiple classifiers on same image.
			return detectOnII(ii, boundaryRect);
		}
		
		/**
		 * Just like detect, but allows re-use of Integral Image for different detectors on the same image
		 * 
		 * scan classifier across ii at DECREASING scales, looking for objects.
		 * Decreasing scales allow bigger (probably closer) objects to have priority.
		 * Will find at most maxDetect faces.  If maxDetect == -1, find ALL.
		 * 
		 * @param ii:IntegralImage
		 * @param boundaryRect:Rectangle - a rectangle describing the area of the image in which to look.  If null, entire image is used
		 * 
		 * @return Array of Rectangles describing areas where objects were found.
		 */
		public function detectOnII(ii:IntegralImage, boundaryrect:Rectangle = null):Array {
			var toreturn:Array = new Array();
			//return toreturn; //debug.  test ii init.
			//initial scale is the largest that will fit in bd.
			if (boundaryrect == null) {
				boundaryrect = new Rectangle(0, 0, ii.width -1, ii.height - 1);
			}
			
			var scale:Number = boundaryrect.width / classifier.width; //initial guess;
			if (floor(classifier.height * scale) > boundaryrect.height) { //whoops.  too big.  try other dimension
			   scale = boundaryrect.height / classifier.height;
			}
			//scale = 1; //debug
			//trace("detect: scale: " + scale);
			//trace("classifier.width: " + classifier.width);
			//trace("floor(scale*width): " + floor(scale * classifier.width));
			trace("detect, boundaryrect=" + boundaryrect + " minscale=" + minscale);
			trace("detect, classifierHeight=" + classifier.height + " classifierWidth=" + classifier.width);
			var rect:Rectangle = new Rectangle(0, 0, floor(scale * classifier.width), floor(scale * classifier.height));

			var rectStep:int = 2; //shrink smallest dimension of rect by this.  larger dimension scaled accordingly using aspect ratio.
			var totTime:int = getTimer();
			var startTime:int;
		    do {
				startTime = getTimer();
				classifier.setScale(rect);
				//trace("scan: rect: " + rect+", classifier.width:"+classifier.width+", height:"+classifier.height);
				scanImage(classifier, ii, rect, boundaryrect, toreturn);
				if ((maxDetect > 0) && (toreturn.length >= maxDetect)){
					return toreturn;
				}
				//trace("scan took " + (getTimer() - startTime));
				if (aspectRatio >= 1){ //classifier height > classifier width
					rect.height -= rectStep; //= floor(scale * classifier.origheight);
					rect.width = floor(rect.height / aspectRatio);
				}else {
					rect.width -= rectStep; //= floor(scale * classifier.origheight);
					rect.height = floor(rect.width * aspectRatio);
				}
				//return toreturn; //debug.  run only one.
			}while ((rect.height > minscale) && (rect.width > minscale)); 
			//trace("entire empty pass took " + (getTimer() -totTime));
			return toreturn;
		}
		
		/**
		 * scans a classifier at a particular scale across an image from left to right and top to bottom
		 * stores matches in input toreturn array.
		 * 
		 * @param	classifier HaarClassifier
		 * @param	ii IntegralImage
		 * @param	rect Rectangle describing sliding classifier window - x,y will be changed
		 * @param	boundaryrect Rectangle describing search window
		 * @param	toreturn Array in which to store matches
		 */
		protected function scanImage(classifier:HaarClassifier, ii:IntegralImage, rect:Rectangle, boundaryrect:Rectangle, toreturn:Array):void {
			//possible optimization: scale steps up when classifier is scaled up
			//trace("scanImage classifier: " + classifier.width + ", " + classifier.height + ", rect: " + rect);
			var xstep:int = max(floor(classifier.width / classifier.origwidth), 1); //2; // floor(classifier.width / 4);
			var ystep:int = max(floor(classifier.height / classifier.origheight), 1);//2; // floor(classifier.height / 4);
			var ylim:int = boundaryrect.y + boundaryrect.height;
			var xlim:int = boundaryrect.x + boundaryrect.width;
			rect.y = boundaryrect.y;
			while ((classifier.height + rect.y) <= ylim) {
				rect.x = boundaryrect.x;
				while ((classifier.width + rect.x) <= xlim) {
					//trace("checking against " + rect);
					//return;
					if (classifier.evaluateSubImage(ii, rect)) {
						toreturn.push(rect.clone());
						if ((maxDetect > 0) && (toreturn.length >= maxDetect)) {
							return;
						}
					}
					//return; //run only one.
					rect.x += xstep;
				}
				rect.y += ystep;
				//return; //debug, run one line
			}
		}
	}
	
}
