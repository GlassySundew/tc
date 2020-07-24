package tools;

import hxd.Res;
import format.tmx.Data.TmxTileset;
import h2d.Tile;
import format.tmx.Tools;
import format.tmx.Data.TmxMap;
import hxd.BitmapData;
import h2d.Bitmap;
import h3d.Vector;
import format.tmx.Data.TmxPoint;
import format.tmx.Data.TmxObject;

@:publicFields
@:expose
class Util {
	inline static function checkPolyClockwise(points:Array<Dynamic>) {
		var sum = .0;
		for (i in 0...points.length) {
			var actualItpp = (i >= points.length - 1) ? 0 : i + 1;
			sum += (points[actualItpp].x - points[i].x) * (points[actualItpp].y + points[i].y);
		}
		sum < 0 ? 0 : points.reverse();
	}

	inline static function cartToIso(x:Float, y:Float):Vector
		return new Vector((x - y), (x + y) / 2);

	inline static function screenToIsoX(globalX:Float, globalY:Float) {
		return globalX + globalY;
	}

	inline static function screenToIsoY(globalX:Float, globalY:Float) {
		return globalY - globalX / 2;
	}

	inline static function screenToIso(globalX:Float, globalY:Float) {
		return new Vector(screenToIsoX(globalX, globalY), screenToIsoY(globalX, globalY));
	}

	inline static function getS2dScaledWid()
		return (Boot.inst.s2d.width / Const.SCALE);

	inline static function getS2dScaledHei()
		return (Boot.inst.s2d.height / Const.SCALE);

	inline static function getTileFromSeparatedTsx(gid:Int, tileset:TmxTileset):Tile {
		var fixedGId = gid - tileset.firstGID;
		for (i in 0...tileset.tiles.length)
			if (tileset.tiles[i].id == fixedGId && fixedGId > i)
				while (fixedGId > i)
					fixedGId--;
		var imageSource = tileset.tiles[fixedGId];
		
		return Res.loader.load(Const.LEVELS_PATH + imageSource.image.source).toTile();
	}
}
