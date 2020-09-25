package tools;

import format.tmx.Data.TmxTilesetTile;
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
	static var eregClass = ~/\$([a-z_0-9]+)+$/gi;  // regexp to remove 'en.' prefix

	inline static function checkPolyClockwise(points:Array<Dynamic>) {
		var pts = points.copy();
		var sum = .0;
		for (i in 0...pts.length) {
			var actualItpp = (i >= pts.length - 1) ? 0 : i + 1;
			sum += (pts[actualItpp].x - pts[i].x) * (pts[actualItpp].y + pts[i].y);
		}
		sum < 0 ? pts.reverse() : {};
		return pts;
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

	inline static function getTileFromSeparatedTsx(tile:TmxTilesetTile):Tile {
		return Res.loader.load(Const.LEVELS_PATH + tile.image.source).toTile();
	}

	inline static function getTileSource(gid:Int, tileset:TmxTileset):TmxTilesetTile {
		var fixedGId = gid - tileset.firstGID;
		// Костыльный фикс на непоследовательные id тайлов
		for (i in 0...tileset.tiles.length)
			if (tileset.tiles[i].id == fixedGId && fixedGId > i)
				while (fixedGId > i)
					fixedGId--;
		return (tileset.tiles[fixedGId]);
	}
}
