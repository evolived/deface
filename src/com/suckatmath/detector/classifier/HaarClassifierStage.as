/**
* I'm basing this on haarcascade_frontalface_alt.xml, which apparently has degenerate trees.
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector.classifier {
	import flash.geom.Rectangle;

	/**
	* Second level of a HaarClassifier.  A stage is composed of several trees.  The output of the trees is summed, compared against a threshold
	* and either true or false is returned.
	* Also has parent and next because the xml file declares them, but they are unused as of now.
	* 
	*/
	public class HaarClassifierStage {
		/**
		 * threshold to compare tree sums against
		 */
		public var threshold:Number; //floating pt
		/**
		 * Array of HaarClassifierTree
		 */
		public var trees:Array; //of HaarClassifierTree;
		/**
		 * index of parent.  Unused.
		 */
		public var parentIndex:int; //populated but unused
		/**
		 * index of next.  Unused.
		 */
		public var nextIndex:int; //populated but unused
		
		public function HaarClassifierStage() {
			this.trees = new Array();
		}
		
		/**
		 * create a classifier stage from an xml node.  Should be compatible with classifiers from OpenCV, but not guaranteed.
		 * @param	xml subtree node representing a classifier stage
		 * @return
		 */
		public static function fromXML(xml:XML):HaarClassifierStage {
			//trace("hcs inputXML:\n" + xml.toXMLString());
			var toreturn:HaarClassifierStage = new HaarClassifierStage();
			var treesList:XMLList = xml.trees.children();
			for each (var t:XML in treesList) {
				toreturn.trees.push(HaarClassifierTree.fromXML(t));
			}
			//trace("thresh: " + xml.stage_threshold.text()[0].toString());
			toreturn.threshold = parseFloat(xml.stage_threshold.text()[0].toString());
			toreturn.parentIndex = parseInt(xml.parent.toString());
			toreturn.nextIndex = parseInt(xml.next.toString());
			return toreturn;
		}
		
		/**
		 * serialize this stage to xml.  Intended to be compatible with OpenCV, but not identical.
		 * @return String representing this classifier as xml
		 */
		public function toXMLString():String {
			var toreturn:String = "<HaarClassifierStage><trees>";
			for (var i:int = 0; i < trees.length; i++) {
				toreturn += "\n" + trees[i].toXMLString();
			}
			toreturn += "</trees>\n<stage_threshold>" + threshold + "</stage_threshold>";
			toreturn += "\n<parent>" + parentIndex + "</parent>";
			toreturn += "\n<next>" + nextIndex + "</next>";
			return toreturn;
		}
		

		
		/**
		 * evals all trees/features, sums their outputs, compares to threshold
		 * 
		 * @param	ii - IntegralImage
		 * @param	r - Rectangle in which to evaluate
		 * @param	vnorm - Number variance normalization factor
		 * @return Boolean, whether this stage passes.
		 */
		public function evaluateSubImage(ii:IntegralImage, r:Rectangle, vnorm:Number):Boolean {
			var tot:Number = 0;
			for (var i:int = 0; i < trees.length; i++) {
			//for (var i:int = 0; i < 1; i++) {
				tot += trees[i].evaluateSubImage(ii, r, vnorm);
			}
			return (tot >= threshold);
		}
		
		/**
		 * scales this stage to a new window size.
		 * Does so by scaling all trees.
		 * @param	w original width
		 * @param	h original height
		 * @param	r new Rectangle window
		 */
		public function setScale(w:int, h:int, r:Rectangle):void {
			for (var i:int = 0; i < trees.length; i++) {
				trees[i].setScale(w, h, r);
			}
		}
		
	}
	
}
