/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector {
	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * Events for ObjectTracker.  FOUND includes a rectangle (foundRect) in which the object was found.  LOST has null for foundRect.
	 */
	public class TrackerEvent extends Event {
		public static var FOUND:String = "found";
		public static var LOST:String = "lost";
		/**
		 * rectangle where object was found.  For LOST, will be null.
		 */
		public var foundRect:Rectangle;
		
		
		public function TrackerEvent(type:String, rect:Rectangle = null, bubbles:Boolean = false, cancelable:Boolean = false ) {
			super(type, bubbles, cancelable);
			this.foundRect = rect;
		}
		
		public override function clone():Event {
			return new TrackerEvent(type, foundRect, bubbles, cancelable);
		}
	}
	
}
