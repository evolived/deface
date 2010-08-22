﻿/*** @author Steve Shipman* @version 0.1*/package com.suckatmath.detector.classifier{	import flash.display.BitmapData;	import flash.filters.ColorMatrixFilter;	import flash.geom.Matrix;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.utils.ByteArray;	import flash.utils.getTimer;	/**	* Both integral image and squared integral image + utility functions and properties.	* Integral image is described in Viola and Jones.  It's basically an array corresponding to pixels in which each value is the sum of all	* pixels up and to the left of the array position, inclusive.	* Squared integral image is similar, but with squared pixel values	* Also has a tilted sum array, in which the values are the sum of all pixels in the image above and to the left if the image were rotated 45 degrees.	*/	public class BasicIntegralImage implements IntegralImage	{		private static  var floor:Function = Math.floor;		private static  var bwmat:Array = [0, 0, 0, 0, 0,		0, 0, 0, 0, 0,		.2989, .587, .114, 0, 0,		0, 0, 0, 0, 0];		private static  var bwfilter:ColorMatrixFilter = new ColorMatrixFilter(bwmat);		/**		 * Array (width by height) of Number.  Each entry is the sum of all pixels above and left of pixel at that index, inclusive		 */		public var sum:Vector.<Number>;//of Number;		/**		 * Array (width by height) of Number.  Each entry is the sum of all pixels (squared) above and left of pixel at that index, inclusive		 */		public var sqsum:Vector.<Number>;//of Number;		/**		 * Array (width by height) of Number.  Each entry is the sum of all pixels above and left (if the image was rotated 45 degrees) of pixel at that index, inclusive		 */		public var tiltsum:Vector.<Number>;//of Number;				private var tiltEnabled:Boolean;		/**		 * width in pixels.  Actually width of input BitmapData + 1 for padding zeros		 */		public var width:int;		/**		 * height in pixels.  Actually height of input BitmapData + 1 for padding zeros		 */		public var height:int;				private var padded:BitmapData				private var bd:BitmapData				private var paddedPoint:Point				private var pixelCount:int		private var zero:Point		private var rect:Rectangle		private var i_m:Vector.<Number>;		/**		 * Construct an IntegralImage from a BitmapData		 * @parambd		 */		public function BasicIntegralImage(bd:BitmapData)		{			this.bd=bd			width = bd.width+1;			height = bd.height+1;			trace(width+":"+height)			pixelCount=width*height			sum = new Vector.<Number>(pixelCount, true);			sqsum = new Vector.<Number>(pixelCount, true);			tiltsum = new Vector.<Number>(pixelCount, true);			tiltEnabled = false;			padded = new BitmapData(width,height, false, 0x00000000 );			paddedPoint=new Point(1,1)			zero=new Point(0,0)			rect=padded.rect			i_m=new Vector.<Number>(pixelCount, true);		}				public function getWidth():int {			return width;		}				public function getHeight():int {			return height;		}				/**		 * tilt is disabled by default because it is computationally expensive and several classifiers do not need it.		 * you can enable it by passing true to this method.		 * @param	t		 */		public function setTiltEnabled(t:Boolean):void {			tiltEnabled = t;		}				/**		 * update from bitmap contents, and calculate new integral image values.		 * internally delegates to different methods for tilt and non-tilt cases.		 */		public function update():void {			if (tiltEnabled) {				updateWithTilt();			}else {				updateWithoutTilt();			}		}				/**		 * calculate integral image values including tilted values		 */		private function updateWithTilt():void		{			padded.applyFilter(bd, bd.rect, paddedPoint, bwfilter);			var ba:Vector.<uint> = padded.getVector(rect);			sum[0] = 0;			sqsum[0] = 0;			tiltsum[x] = 0; //dunno.			for (var i:int = 0; i < pixelCount; i++)			{				i_m[i] = ((ba[i]) & 0xff) / 255;			}			var px:int			var pimx:Number			for (var x:int = 1; x < width; x++)			{				px=x-1				pimx = i_m[x]; // as Number;				sum[x] = sum[px] + pimx;				sqsum[x] = sqsum[px] + pimx * pimx;				tiltsum[x] = 0; //dunno.			}			var r:Number;			var rs:Number;			var Y:int = width;			var YY:int = 0;			var yx:int			var yyx:int			var imy:Number			for (var y:int = 1; y < height; y++, Y+=width, YY+=width)			{				r = 0;				rs = 0;				for (x = 0; x < width; x++)				{					yx=Y+x					yyx=YY+x					imy = i_m[yx]; // as Number					r += imy;					rs += imy*imy;					sum[yx] = sum[yyx] + r;					sqsum[yx] = sqsum[yyx] + rs;					tiltsum[yx] = getTiltSumXY(tiltsum, x-1, y-1) + getTiltSumXY(tiltsum, x+1, y-1) 						- getTiltSumXY(tiltsum, x, y - 2) + i_m[yx] + i_m[Y-width+x];				}			}		}					/**		 * calculate integral image values withOUT tilted.		 */		private function updateWithoutTilt():void		{			padded.applyFilter(bd, bd.rect, paddedPoint, bwfilter);			var ba:Vector.<uint> = padded.getVector(rect);			sum[0] = 0;			sqsum[0] = 0;			tiltsum[x] = 0; //dunno.			for (var i:int = 0; i < pixelCount; i++)			{				i_m[i] = ((ba[i]) & 0xff) / 255;			}			var px:int			var pimx:Number			for (var x:int = 1; x < width; x++)			{				px=x-1				pimx = i_m[x]; // as Number				sum[x] = sum[px] + pimx;				sqsum[x] = sqsum[px] + pimx * pimx;			}			var r:Number;			var rs:Number;			var Y:int = width;			var YY:int = 0;			var yx:int			var yyx:int			var imy:Number			for (var y:int = 1; y < height; y++, Y+=width, YY+=width)			{				r = 0;				rs = 0;				for (x = 0; x < width; x++)				{					yx=Y+x					yyx=YY+x					imy = i_m[yx]; // as Number;					r += imy;					rs += imy*imy;					sum[yx] = sum[yyx] + r;					sqsum[yx] = sqsum[yyx] + rs;				}			}		}			/**		 * utility function to get tilted sum array.  Tests for array bounds and returns safe 0 values.		 * @param	tiltarr - tilted sum array		 * @param	x - int pixel location x		 * @param	y - int pixel location y		 * @return		 */		private function getTiltSumXY(tiltarr:Vector.<Number>, x:int, y:int):Number{			if (x < 0){				return 0;			}			if (y < 0){				return 0;			}			return tiltarr[y*width+x];					}				public function getRectSum(r:Rectangle):Number		{			var rx:int = r.x;			var ry:int = r.y;			var rw:int = r.width;			var rh:int = r.height;			var a:int = ((ry + rh) * width) + rx + rw;			var b:int = (ry * width) + rx + rw;			var c:int = (ry + rh) * width + rx;			var d:int = (ry * width) + rx;			/*			var s1:Number = sum[a]; // as Number;			var s2:Number = sum[b]; // as Number;			var s3:Number = sum[c]; // as Number;			var s4:Number = sum[d]; // as Number;			*/			//return s1 - s2 - s3 + s4;			return sum[a] - sum[b] - sum[c] + sum[d];		}		/**		 * Gets sum of pixels in r from tilted image.		 * @paramr unrotated rect as defined in HaarRect		 * @return sum from tilted sum of the input rectangle rotated 45 degrees		 */		public function getTiltRectSum(r:Rectangle):Number		{			var ry:int = r.y;			var rx:int = r.x;			var rw:int = r.width;			var rh:int = r.height;			var a:int = (ry + rw) * width + rx + rw;			var b:int = (ry + rh) * width + rx - rh;			var c:int = ry * width + rx;			var d:int = (ry+rw+rh)*width + rx + rw -rh;			var s1:Number = tiltsum[a]; // as Number;			var s2:Number = tiltsum[b]; // as Number;			var s3:Number = tiltsum[c]; // as Number;			var s4:Number = tiltsum[d]; // as Number;			return s1 + s2 - s3 - s4;		}				/**		 * calculates sum of squared pixel values in rectangle.  Used for normalization		 * @paramr rectangle on which to calculate squared sum		 * @return sum of squared pixel values in r		 */		public function getRectSqSum(r:Rectangle):Number		{			var rx:int = r.x;			var ry:int = r.y;			var rw:int = r.width;			var rh:int = r.height;			var a:int = ((ry + rh) * width) + rx + rw;			var b:int = (ry * width) + rx + rw;			var c:int = (ry + rh) * width + rx;			var d:int = (ry * width) + rx;			var s1:Number = sqsum[a]; // as Number;			var s2:Number = sqsum[b]; // as Number;			var s3:Number = sqsum[c]; // as Number;			var s4:Number = sqsum[d]; // as Number;			return s1 - s2 - s3 + s4;		}		/**		 * gets a string representation.   Very verbose for large images.		 * @return String 		 */		public function toString():String		{			var toreturn:String = "sum=\n";			var sqstring:String = "sqsum=\n";			for (var i:int = 0; i < height; i++)			{				toreturn += "[";				sqstring += "[";				for (var j:int = 0; j < width; j++)				{					toreturn += sum[i * width + j] + " ";					sqstring += sqsum[i * width + j] + " ";				}				toreturn += "]\n";				sqstring += "]\n";			}			toreturn += sqstring;			return toreturn;		}	}}