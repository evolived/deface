/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector {
	import com.suckatmath.detector.classifier.*;
	import flash.errors.IllegalOperationError;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	/**
	 * A single object detector which iteratively restricts its search window until it no longer finds anything.
	 */
	public class FocussedDetector extends Detector{
		
		/**
		 * 
		 * @param	hc Classifier to use
		 * @param	md maxDetect - This will be ignored as it must always be set to -1 (ALL)
		 * @param	minscale size of smallest feature to find (in pixels)
		 */
		public function FocussedDetector(hc:HaarClassifier = null, md:int = 1, minscale:int = 20 ):void {
			super(hc, -1, minscale);
		}
		
		
		/**
		 * Override from Detector so that maxDetect cannot be set to anything other than -1
		 * @param	md
		 */
		public override function setMaxDetect(md:int):void {
			//do nothing!
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
		public override function detectOnII(ii:IntegralImage, boundaryrect:Rectangle = null):Array {
			var toreturn:Array = new Array();
			var intersect:Rectangle;
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
			//trace("detect, boundaryrect=" + boundaryrect + " minscale=" + minscale);
			//trace("detect, classifierHeight=" + classifier.height + " classifierWidth=" + classifier.width);
			var rect:Rectangle = new Rectangle(0, 0, floor(scale * classifier.width), floor(scale * classifier.height));

			var rectStep:int = 2; //shrink smallest dimension of rect by this.  larger dimension scaled accordingly using aspect ratio.
			var totTime:int = getTimer();
			var startTime:int;
			var numFoundBefore:int = 0;
		    do {
				startTime = getTimer();
				classifier.setScale(rect);
				scanImage(classifier, ii, rect, boundaryrect, toreturn);
				if (toreturn.length > numFoundBefore) {
					numFoundBefore = toreturn.length;
					boundaryrect = toreturn[toreturn.length -1].clone();
					boundaryrect.inflate( -1, -1); //shrink boundary by 1
					//trace("shrinking! new boundaryrect="+boundaryrect);
				}
				if (aspectRatio >= 1){ //classifier height > classifier width
					rect.height -= rectStep; //= floor(scale * classifier.origheight);
					rect.width = floor(rect.height / aspectRatio);
				}else {
					rect.width -= rectStep; //= floor(scale * classifier.origheight);
					rect.height = floor(rect.width * aspectRatio);
				}
			}while ((rect.height > minscale) && (rect.width > minscale)); 
			if (toreturn.length > 0){
				intersect = toreturn[0];
				for (var i:int = 1; i < toreturn.length; i++) {
					if(intersect.intersects(toreturn[i])){ //have to test because we want to return SOMETHING.
						intersect = intersect.intersection(toreturn[i]);
					}
				}
				return [intersect]; //Array containint intersect
			}else {
				return toreturn; //it's empty anyway
			}
		}
		
	}
	
}
