/**
* @author Steve Shipman
* @version 0.1
*/

package com.suckatmath.detector {
	import com.suckatmath.detector.classifier.IntegralImage;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;

	/**
	 * Uses a detector to find and track objects in BitmapData.  Does so by remembering where the object was last found, and searching only
	 * within a small window around that area.  Detections happen at intervals, and at each either a TrackerEvent.FOUND or TrackerEvent.LOST is
	 * dispatched.
	 * 
	 * @see TrackerEvent
	 */
	public class ObjectTracker extends EventDispatcher{
		/**
		 * Detector to use to find objects
		 */
		public var detector:Detector; //use this to detect.
		/**
		 * Rectangle where the last object was found
		 */
		public var foundRect:Rectangle; //only track single.  Other classes can poll this to get current pos
		/**
		 * Underlying BitmapData to watch
		 */
		private var bd:BitmapData;
		
		private var detecting:Boolean;
		private var iterScale:Number; //factor by which to scale detector down and up each iteration
		private var rects:Array;
		private var originalMinScale:int;

		private var timer:Timer;
		
		private var max:Function = Math.max;
		private var min:Function = Math.min;
		private var floor:Function = Math.floor;
		
		/**
		 * Constructs an ObjectTracker. 
		 * @param	d  detector to use
		 * @param	bd  bitmap data to monitor
		 * @param	interval  time in ms between detections
		 * @param	iterscale factor to scale up/down search window between detections
		 * @param	initialRect where to look.
		 * @throws ArgumentError if iterscale is not between 0 and 1.
		 */
		public function ObjectTracker(d:Detector, bd:BitmapData, interval:int, iterscale:Number = 0.2, initialRect:Rectangle = null ) {
			this.detector = d;
			this.detector.setMaxDetect(1); //only support one face/object right now.
			this.originalMinScale = this.detector.minscale;
			this.bd = bd;
			this.iterScale = iterscale;
			if (!((iterscale > 0) && (iterscale < 1))) {
				throw new ArgumentError("iterscale must be between 0 and 1.  Default is 0.2");
			}
			timer = new Timer(interval);
			timer.addEventListener(TimerEvent.TIMER, handleTimer);
			foundRect = initialRect;
			this.detecting = false;
		}
	
		/**
		 * stop internal timer, any current detection completes, but next won't be triggered.
		 */
		public function stop():void {
			timer.reset();
		}

		/**
		 * starts internal timer.  track will happen after interval.
		 */
		public function start():void {
			timer.start();
		}
		
		/**
		 * kick off track, but only if it's not already going.
		 * @param	event
		 */
		private function handleTimer(event:TimerEvent):void{
			if (!detecting){
				track();
			}
		}
		
		
		/**
		 * do a detection, and send off event.
		 * 
		 * May send a FOUND event or a LOST event.
		 * 
		 */
		private function track():void {
			trace("track");
			detecting = true;
			var stime:int = getTimer();
			if (foundRect != null) {
				//scale rect up by iterScale, and detector.minScale down.
				var prevw:int = foundRect.width;
				var prevh:int = foundRect.height;
				var delta:int = floor(foundRect.height * iterScale);
				detector.minscale = floor(foundRect.height * (1 - iterScale)); //assumes square classifier
				foundRect.width += delta;
				foundRect.height += delta
				foundRect.x -= floor((foundRect.width - prevw) / 2);
				if (foundRect.x < 0) {
					foundRect.x = 0;
				}
				foundRect.y -= floor((foundRect.height - prevh) / 2);
				if (foundRect.y < 0) {
					foundRect.y = 0;
				}
				if (foundRect.x + foundRect.width > bd.width) {
					foundRect.width = bd.width - foundRect.x;
				}
				if (foundRect.y + foundRect.height > bd.height) {
					foundRect.height = bd.height - foundRect.y;
				}
				var rects:Array = detector.detect(bd, foundRect);
				if (rects.length > 0) {
					foundRect = rects[0];
				}else {
					foundRect = null;
				}
			}else { //no idea where it is.
				detector.minscale = originalMinScale;
				rects = detector.detect(bd);
				if (rects.length > 0) {
					foundRect = rects[0];
				}
			}
			if (foundRect != null){
				trace("found " + foundRect + " in " + (getTimer() - stime));
				dispatchEvent(new TrackerEvent(TrackerEvent.FOUND, foundRect));
			}else {
				trace("lost in " + (getTimer() - stime));
				dispatchEvent(new TrackerEvent(TrackerEvent.LOST, foundRect));
			}
			detecting = false;
		}
	}
	
}
