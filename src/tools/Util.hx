package tools;

import hxd.BitmapData;
import h2d.Bitmap;
import h3d.Vector;
import format.tmx.Data.TmxPoint;
import format.tmx.Data.TmxObject;

@:publicFields
class Util {
	inline static function checkPolyClockwise(points:Array<Dynamic>) {
		var sum = .0;
		for (i in 0...points.length) {
			var actualItpp = (i >= points.length - 1) ? 0 : i + 1;
			sum += (points[actualItpp].x - points[i].x) * (points[actualItpp].y + points[i].y);
		}
		sum < 0 ?  0: points.reverse();
	}

	inline static function cart_to_iso(x:Float, y:Float):Vector
		return new Vector((x - y), (x + y) / 2);

	/**
		Get texture width and height by removing alpha pixels
	**/
	inline static function trimTile(tile:h2d.Tile):Vector {
		var w = 0, h = 0, wBot = 0, wTop = 0., hBot = 0, hTop = 0.;
		var breakOut = false;

		// for (i in 0...Std.int(tile.height)) {
		// 	for (j in 0...Std.int(tile.width)) {
		// 		trace(pixels.getPixel(j, i), j, i);
		// 		if (pixels.getPixel(j, i) != 0) {
		// 			hBot = i;
		// 			breakOut = tru;e
		// 			break;
		// 		}
		// 	}
		// 	if (breakOut)
		// 		break;
		// }
		// breakOut = false;
		// var ih = tile.height;
		// while (ih >= 0) {
		// 	ih--;
		// 	trace(ih);
		// 	for (j in 0...pixels.width)
		// 		if (pixels.getPixel(j, Std.int(ih)) != 0) {
		// 			hTop = ih - 1;
		// 			breakOut = true;
		// 			break;
		// 		}
		// 	if (breakOut)
		// 		break;
		// }
		// breakOut = false;
		// for (i in 0...pixels.width) {
		// 	for (j in 0...pixels.height)
		// 		if (pixels.getPixel(i, j) != 0) {
		// 			wBot = i - 1;
		// 			breakOut = true;
		// 			break;
		// 		}
		// 	if (breakOut)
		// 		break;
		// }
		// breakOut = false;
		// for (i in pixels.width...0) {
		// 	for (j in 0...pixels.height)
		// 		if (pixels.getPixel(i, j) != 0) {
		// 			wTop = i + 1;
		// 			breakOut = true;
		// 			break;
		// 		}
		// 	if (breakOut)
		// 		break;
		// }
		trace(wBot, wTop, hBot, hTop);
		return new Vector(w, h);
	}
}
