package  com.suckatmath.example
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.filters.ShaderFilter;
	import flash.media.Video;
	import flash.display.Sprite;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	import com.suckatmath.detector.classifier.HaarClassifier;
	import com.suckatmath.detector.Detector;
	import com.suckatmath.detector.BigToSmallDetector;
	import flash.geom.Rectangle;
	import flash.events.ActivityEvent;
	
	/**
	 * ...
	 * @author ...
	 */
	public class FaceTracker extends Sprite
	{
		private var camera:Camera;
		private var video:Video;
		private var outputSprite:Sprite;
		private var bd:BitmapData;
		private var myLoader:URLLoader;
		private var busy:Boolean;
		private var detector:Detector;
		private var lastRect:Rectangle;
		private static const XML_URL:String = "../lib/haarcascade_frontalface_alt.xml";

		public function FaceTracker() 
		{
			busy = false;
            camera = Camera.getCamera();
            if (camera != null) {
				//camera.addEventListener(StatusEvent.STATUS, startcam);
				camera.addEventListener(ActivityEvent.ACTIVITY, startcamOnActivity);
				camera.setMode(320, 240, 30, false);
				//camera.setMode(160, 120, 30, false);
               
				video = new Video(camera.width, camera.height);
				video.attachCamera(camera);
				addChild(video);
				bd = new BitmapData(video.width, video.height, true, 0xFF000000);
				outputSprite = new Sprite();
				addChild(outputSprite);
				var outSprite:Sprite = new Sprite();
				addChild(outSprite);
				var myXMLURL:URLRequest = new URLRequest(XML_URL);
				myLoader = new URLLoader();
				myLoader.addEventListener(Event.COMPLETE, xmlLoaded);
				myLoader.load(myXMLURL);
			}
		}
		
		private function xmlLoaded(event:Event):void {
			var myXML:XML = XML(myLoader.data);
			trace("Data loaded.");
			var classifier:HaarClassifier = HaarClassifier.fromXML(myXML.*.(@type_id == "opencv-haar-classifier")[0]);
			detector = new BigToSmallDetector(classifier, 1, 80); //new Detector(classifier, 1, 30);
			detector.bitmap = bd;
			lastRect = bd.rect.clone();
			
		}
		
		private function startcam(event:StatusEvent):void {
			trace("startcam!");
			if (event.code != "Camera.Muted") {
				trace("startcam go!");
				addEventListener(Event.ENTER_FRAME, detectAndHighlite);
			}
		}
		
		private function startcamOnActivity(event:ActivityEvent):void {
			trace("startcamOnActivity!");
			camera.removeEventListener(ActivityEvent.ACTIVITY, arguments.callee);
			addEventListener(Event.ENTER_FRAME, detectAndHighlite);
		}
		
		private function detectAndHighlite(event:Event):void {
			if (busy) {
				return;
			}
			busy = true;
			var before:int = getTimer();
			bd.draw(video);
			var faceRects:Vector.<Rectangle> = detector.detect(lastRect);
			var after:int = getTimer();
			//trace("took: " + (after - before));
			if (faceRects != null) {
				//trace("lastRect (before inflate):" + faceRects[0]);
				setLastRect(faceRects[0]);
				//trace("lastRect (after inflate):" +lastRect);
				outputSprite.graphics.clear();
				outputSprite.graphics.lineStyle(0.1, 0x00ff00);
				for (var i:int = 0; i < faceRects.length; ++i){
					outputSprite.graphics.drawRect(faceRects[i].x, faceRects[i].y, faceRects[i].width, faceRects[i].height);
				}
			}else {
				trace("lost it, lastrect:"+lastRect);
				setLastRect(bd.rect);
			}
			busy = false;
		}
		
		private function setLastRect(r:Rectangle):void {
			var margin:int = 8;
			var mar2:int = margin << 1;
			lastRect.x = r.x >= margin ? r.x - margin : 0;
			lastRect.width = r.right <= bd.width - margin ? r.width + mar2 : bd.width - r.x;
			lastRect.y = r.y >= margin ? r.y - margin : 0;
			lastRect.height = r.bottom <= bd.height - margin ? r.height + mar2 : bd.height - r.y;
		}
		
	}
	
}