/**
* 
* @author Steve Shipman
* @version 0.1
*/

package  com.suckatmath.detector.classifier {
	import flash.geom.Rectangle;

	/**
	 * A Haar Classifier Feature is an element of a HaarClassifierTree.
	 * 
	 * As a Feature, it has rects, threshold, leftval, rightval, left index, right index
	 */
	public class HaarClassifierFeature {
		/**
		 * Array of HaarRect
		 */
		public var rects:Array; //of HaarRect;
		/**
		 * threshold to compare sums against
		 */
		public var threshold:Number; //float
		/**
		 * whether this feature is "tilted" 45 degrees
		 */
		public var tilted:Boolean; 
		/**
		 * Number to return if sums are less than threshold.  May be NaN iff leftIdx != NaN
		 */
		public var leftval:Number; //float.  may be NaN iff leftIdx != NaN
		/**
		 * Number to return if sums are more than threshold.  May be NaN iff rightIdx != NaN
		 */
		public var rightval:Number; //float. may be NaN iff rightIdx != NaN
		/**
		 * index in parent of left child feature.  May be NaN iff leftval != NaN
		 */
		public var leftIdx:int; //index in parent of left child feature.  may be null iff leftval != null
		/**
		 * index in parent of right child feature.  May be NaN iff rightval != NaN
		 */
		public var rightIdx:int; //index in parent of left child feature.  may be null iff leftval != null
		/**
		 * inverse of scaled window area. 1/(width times height).  Used for normalization.
		 */
		public var inv_window_area:Number; //float
		
		/**
		 * parent HaarClassifierTree.  Used for tree traversal.
		 */
		public var parent:HaarClassifierTree; //parent tree.  used for traversal.
		
		
		public function HaarClassifierFeature() {
			rects = new Array();
		}
		
		/**
		 * read a feature from an xml node.  Intended to be compatible with OpenCV xml classifiers, but this project is NOT associated
		 * with OpenCV
		 * @param	xml subtree representing a classifier feature
		 * @return HaarClassifierFeature
		 */
		public static function fromXML(xml:XML):HaarClassifierFeature {
			var toreturn:HaarClassifierFeature = new HaarClassifierFeature();
			toreturn.threshold = parseFloat(xml.threshold.text()[0].toString());
			//test for left_val.
			if (xml.descendants("left_val").length() > 0){
				toreturn.leftval = parseFloat(xml.left_val.text()[0].toString());
				toreturn.leftIdx = NaN;
			}else {
				toreturn.leftIdx = parseInt(xml.left_node.text()[0].toString());
				toreturn.leftval =  NaN;
			}
			//test for right_val.
			if (xml.descendants("right_val").length() > 0){
				toreturn.rightval = parseFloat(xml.right_val.text()[0].toString());
				toreturn.rightIdx = NaN;
			}else {
				toreturn.rightIdx = parseInt(xml.right_node.text()[0].toString());
				toreturn.rightval = NaN;
			}
			toreturn.tilted = (parseInt(xml.feature.tilted.text()[0].toString()) == 1);

			var rectsnodes:XMLList = xml.feature.rects.children();
			//we ignore tilted as well, since it's always 0 in our example
			var rarray:Array; //of String.  Basically the numbers in the individual rect nodes
			var x:int;
			var y:int;
			var w:int;
			var h:int;
			var weight:Number;
			for each (var r:XML in rectsnodes) {
				rarray = r.text()[0].toString().split(" ");
				x = parseInt(rarray[0]);
				y = parseInt(rarray[1]);
				w = parseInt(rarray[2]);
				h = parseInt(rarray[3]);
				weight = parseFloat(rarray[4]);
				toreturn.rects.push(new HaarRect(x, y, w, h, weight));
			}
			return toreturn;
		}
		
		
		/**
		 * serialize this feature to an xml string.  Intended to be compatible with OpenCV but not identical.
		 * @return String version of this classifier feature as xml
		 */
		public function toXMLString():String {
			var toreturn:String = "<HaarClassifierFeature><feature><rects>";
			for (var i:int = 0; i < rects.length; i++) {
				toreturn += "\n" + rects[i].toXMLString();
			}
			toreturn += "</rects><tilted>";
			if (tilted) {
				toreturn += "1";
			}else {
				toreturn += "0";
			}
			toreturn += "</tilted></feature>";
			toreturn += "\n<threshold>" + threshold + "</threshold>";
			if (!isNaN(leftval)){
				toreturn += "<left_val>" + leftval + "</left_val>";
			}else {
				toreturn += "<left_node>" + leftIdx +"</left_node>";
			}
			if (!isNaN(rightval)) {
				toreturn += "<right_val>" + rightval + "</right_val>";
			}else {
				toreturn += "<right_node>" + rightIdx +"</right_node>";
			}
			toreturn += "</HaarClassifierFeature>";
			return toreturn;
		}
		
		/**
		 * evaluates this feature in the context of a search window.
		 * 
		 * @param	ii IntegralImage to use for sums
		 * @param	r Rectangle window in which to look
		 * @param	vnorm Number variance normalization factor.
		 * @return Number which is either leftval, rightval, or the result of evaluating a sibling feature
		 */
		public function evaluateSubImage(ii:IntegralImage, r:Rectangle, vnorm:Number):Number {
			var rectsTot:Number = 0.0;
			var rres:Number;
			for (var i:int = 0; i < rects.length; i++) {
				rres = rects[i].evaluateSubImage(ii, r, tilted);
				//trace("rects[" + i + "]: "+rects[i].operatingRect+" evals to: " + rres);
				rectsTot += rres; // rects[i].evaluateSubImage(ii, r);
			}
			rectsTot = rectsTot * inv_window_area;  //divide by area.  reference alg doesn't have this, but otherwise scale seems off. 
			//trace("HaarClassifierTree: rectsTot: " + rectsTot + " vs thresh: " + (threshold*vnorm) +" (t:"+threshold+", vnorm:"+vnorm+")");
			if (rectsTot >= (threshold * vnorm)) {
				if (!isNaN(rightval)){
					return rightval;
				}else {
					return parent.nodes[rightIdx].evaluateSubImage(ii, r, vnorm);
				}
			}else {
				if (!isNaN(leftval)){
					return leftval;
				}else {
					return parent.nodes[leftIdx].evaluateSubImage(ii, r, vnorm);
				}
			}
		}
		
		/**
		 * Scales this feature to the new size of a window
		 * @param	w original window width
		 * @param	h original window height
		 * @param	r new Rectangle window.
		 */
		public function setScale( w:int, h:int, r:Rectangle):void {
			for (var i:int = 0; i < rects.length; i++) {
				rects[i].setScale(w,h,r);
			}
			inv_window_area = 1 / (r.width * r.height);
		}
		
	}
	
}
