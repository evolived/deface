/**
* @author Steve Shipman
* @version 0.1
*/

package  com.suckatmath.detector.classifier{
	
	import flash.geom.Rectangle;

	/**
	* HaarClassifier is the top level of a Haar Classifier.  It has a native width and height and several stages.
	* Corresponds to <... type_id="opencv-haar-classifier">
	* 
	*/
	public class HaarClassifier {
		/**
		 * width in pixels
		 */
		public var width:int;
		/**
		 * height in pixels
		 */
		public var height:int;
		/**
		 * original width (before any scaling)
		 */
		public var origwidth:int;
		/**
		 * original height (before any scaling)
		 */
		public var origheight:int;
		/**
		 * inverse window area.  1/(width times height).  Used for normalization
		 */
		public var inv_window_area:Number;
		/**
		 * Array of HaarClassifierStage
		 */
		public var stages:Array; //of HaarClassifierStage
		
		private var sqrt:Function = Math.sqrt;
		
		/**
		 * Create a new classifier.  Usually you won't use this, instead reading from XML using the fromXML method
		 * @param	w  native width in pixels.
		 * @param	h  native height in pixels.
		 */
		public function HaarClassifier(w:int = 0, h:int = 0):void {
			this.width = w;
			this.origwidth = this.width;
			this.height = h;
			this.origheight = this.height;
			this.stages = new Array();
		}
		
		/**
		 * reads a HaarClassifier from an XML file.  Several such files are provided by the Intel OpenCV project.  This class intends to be
		 * compatible with those files, but is NOT associated with the OpenCV project.
		 * 
		 * @param	xml
		 * @return HaarClassifier described by the xml
		 */
		public static function fromXML(xml:XML):HaarClassifier {
			var sizes:XML = xml.size.text()[0];
			trace("sizes: " + sizes.toString());
			var sizesArr:Array = sizes.toString().match( /\d+/g );
			var toreturn:HaarClassifier = new HaarClassifier(sizesArr[0], sizesArr[1]);
			var stagesList:XMLList = xml.stages[0].children();
			var astage:HaarClassifierStage;
			for each (var s:XML in stagesList) {
				astage = HaarClassifierStage.fromXML(s);
				toreturn.stages.push(astage);
			}
			return toreturn;
		}
		
		
		/**
		 * serialize this classifier to an XML string suitable for writing to a file.  Should be compatible with OpenCV, but not identical.
		 * some nodes which OpenCV represents as "_" are more verbose.
		 * 
		 * @return String
		 */
		public function toXMLString():String {
			var toreturn:String =  '<HaarClassifier type="opencv-haar-classifier"><size> ' + origwidth + " " + origheight + "</size><stages>";
			for (var i:int = 0; i < stages.length; i++) {
				toreturn += "\n"+ stages[i].toXMLString();
			}
			toreturn += "</stages></HaarClassifier>";
			return toreturn;
		}
		
		/**
 		 *  iteratively evaluates stages.  Passes if ALL stages pass.
		 * 
		 * @param	ii - IntegralImage
		 * @param	r - window on which to evaluate.
		 * @return true if ALL stages pass.  false otherwise.
		 */
		public function evaluateSubImage(ii:IntegralImage, r:Rectangle):Boolean {
			var mean:Number = ii.getRectSum(r) * inv_window_area;
			//trace("rectsqsum: " + ii.getRectSqSum(r));
			//trace("meansquare: " + (mean * mean));
			var vnorm:Number = (ii.getRectSqSum(r) * inv_window_area) - (mean * mean) ;
			//trace("vnorm: " + vnorm);
			
			if (vnorm >= 0) {
				vnorm = sqrt(vnorm);
			}else {
				vnorm = 1.0;
			}
			
			
			for (var i:int = 0; i < stages.length; i++) {
				if (!stages[i].evaluateSubImage(ii, r, vnorm)) {
//					if (i > 9){
//						trace("died at stage: " + i + " of "+stages.length+", r: "+r);
//					}
					return false;
				}
				//trace("pass HaarClassifierStage");
			}
			return true;
		}
		
		/**
		 * scales this classifier from width * height to r.
		 * Does so by scaling all rectangle features in subtrees.
		 * @param	r window to scale to.
		 */
		public function setScale(r:Rectangle) : void{
			for (var i:int = 0; i < stages.length; i++) {
				stages[i].setScale(origwidth, origheight, r);
			}
			height = r.height;
			width = r.width;
			inv_window_area = 1 / (r.width * r.height);
			
		}
		
	}
	
}
