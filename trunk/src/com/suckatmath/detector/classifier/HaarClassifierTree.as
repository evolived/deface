/**
* 
* @author Steve Shipman
* @version 0.1
*/

package  com.suckatmath.detector.classifier {
	import flash.geom.Rectangle;
	/**
	 * A Haar Classifier Tree is an element of a HaarClassifierStage.  These have an array of nodes (one or more), which form a tree.
	 */
	public class HaarClassifierTree {
		/**
		 * Array of HaarClassifierFeature
		 */
		public var nodes:Array;
		
		public function HaarClassifierTree() {
			nodes = new Array();
		}
		
		/**
		 * create a classifier tree from xml.  Should be compatible with OpenCV classifiers, but not guaranteed.
		 * @param	xml subtree representing a classifier tree
		 * @return HaarClassifierTree
		 */
		public static function fromXML(xml:XML):HaarClassifierTree {
			var toreturn:HaarClassifierTree = new HaarClassifierTree();
			var nodeNodes:XMLList = xml.elements(); //does NOT include comments
			var feat:HaarClassifierFeature;
			for each(var featNode:XML in nodeNodes) {
				feat = HaarClassifierFeature.fromXML(featNode);
				feat.parent = toreturn;
				toreturn.nodes.push(feat);
			}
			return toreturn;
		}
		
		/**
		 * serialize this classifier tree to xml.  Should be compatible with OpenCV but not identical
		 * @return String version of this classifier tree as xml
		 */
		public function toXMLString():String {
			var toreturn:String = "<HaarClassifierTree>";
			for (var i:int = 0; i < nodes.length; i++) {
				toreturn += "\n" + nodes[i].toXMLString();
			}
			toreturn += "</HaarClassifierTree>";
			return toreturn;
		}
		
		
		/**
		 * evaluate root node (feature).  The individual features control tree traversal among siblings.
		 * @param	ii IntegralImage to use for sums
		 * @param	r Rectangle window to evaluate
		 * @param	vnorm Number variance normalization factor
		 * @return
		 */
		public function evaluateSubImage(ii:IntegralImage, r:Rectangle, vnorm:Number):Number {
			return nodes[0].evaluateSubImage(ii, r, vnorm);
		}
		
		/**
		 * scale this tree to r by scaling each child node.
		 * @param	w original classifier width
		 * @param	h original classifier height
		 * @param	r new window Rectangle
		 */
		public function setScale( w:int, h:int, r:Rectangle):void {
			for (var i:int = 0; i < nodes.length; i++) {
				nodes[i].setScale(w,h,r);
			}
		}
		
	}
	
}
