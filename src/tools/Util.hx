package tools;

import h3d.Vector;
import format.tmx.Data.TmxPoint;
import format.tmx.Data.TmxObject;

@:publicFields
class Util {
	inline static function chech_poly_clockwise(poly:TmxObject, points:Array<TmxPoint>) {
		var sum = .0;
		for (i in 0...points.length) {
			var actualItpp = (i >= points.length - 1) ? 0 : i + 1;
			sum += (points[actualItpp].x - points[i].x) * (points[actualItpp].y + points[i].y);
		}
		sum < 0 ? points.reverse() : 0;
	}

	inline static function cart_to_iso(x:Float, y:Float):Vector
		return new Vector((x - y), (x + y) / 2);
}
