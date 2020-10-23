package tools;

import h2d.Scene;
import h3d.pass.Default;
import format.tmx.Data.TmxLayer;
import format.tmx.Reader;
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
	/**Regex to get class name provided by CompileTime libs, i.e. en.$Entity -> Entity **/
	static var eregCompTimeClass = ~/\$([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Regex to get '$this' class name i.e. en.Entity -> Entity **/
	static var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Регулярка чтобы взять из абсолютного пути название файла без расширения .png **/
	static var eregFileName = ~/\/([a-z_0-9]+)\./;

	inline static function checkPolyClockwise(points: Array<Dynamic>) {
		var pts = points.copy();
		var sum = .0;
		for (i in 0...pts.length) {
			var actualItpp = (i >= pts.length - 1) ? 0 : i + 1;
			sum += (pts[actualItpp].x - pts[i].x) * (pts[actualItpp].y + pts[i].y);
		}
		sum < 0 ? pts.reverse() : {};
		return pts;
	}

	inline static function cartToIso(x: Float, y: Float): Vector return new Vector((x - y), (x + y) / 2);

	inline static function screenToIsoX(globalX: Float, globalY: Float) {
		return globalX + globalY;
	}

	inline static function screenToIsoY(globalX: Float, globalY: Float) {
		return globalY - globalX / 2;
	}

	inline static function screenToIso(globalX: Float, globalY: Float) {
		return new Vector(screenToIsoX(globalX, globalY), screenToIsoY(globalX, globalY));
	}

	inline static function getS2dScaledWid() return (Boot.inst.s2d.width / Const.SCALE);

	inline static function getS2dScaledHei() return (Boot.inst.s2d.height / Const.SCALE);

	inline static function getTileFromSeparatedTsx(tile: TmxTilesetTile): Tile {
		return Res.loader.load(Const.LEVELS_PATH + tile.image.source).toTile();
	}

	inline static function getTileSource(gid: Int, tileset: TmxTileset): TmxTilesetTile {
		var fixedGId = gid - tileset.firstGID;
		// фикс на непоследовательные id тайлов
		for (i in 0...tileset.tiles.length) if (tileset.tiles[i].id == fixedGId && fixedGId > i) while (fixedGId > i)
			fixedGId--;
		return (tileset.tiles[fixedGId]);
	}

	inline static function getTsx(tsx: Map<String, TmxTileset>, r: Reader): String->TmxTileset {
		return (name: String) -> {
			var cached: TmxTileset = tsx.get(name);
			if (cached != null) return cached;
			cached = r.readTSX(Xml.parse(Res.loader.load(Const.LEVELS_PATH + name).entry.getText()));
			tsx.set(name, cached);
			return cached;
		}
	}

	static var entParent: Scene;
}

class TmxMapExtender {
	public static function getLayersByName(tmxMap: TmxMap): Map<String, TmxLayer> {
		var map: Map<String, TmxLayer> = new Map();
		for (i in tmxMap.layers) {
			var name: String = 'null';
			switch (i) {
				case LObjectGroup(group):
					name = group.name;
				case LTileLayer(tl):
					name = tl.name;
				default:
			}
			map.set(name, i);
		}
		return map;
	}
}

class TmxLayerExtender {
	public static function getObjectByName(tmxLayer: TmxLayer, name: String): TmxObject {
		switch (tmxLayer) {
			case LObjectGroup(group):
				for (i in group.objects) {
					if (i.name == name) return i;
				}
			default:
		}
		return null;
	}
	/** Localises all objects of this layer to be local to certain object of this layer **/
	public static function localBy(tmxLayer: TmxLayer, target: TmxObject) {
		switch (tmxLayer) {
			case LObjectGroup(group):
				// Checking if the object belongs to the layer
				var tempCheck = null;
				for (i in group.objects) if (target == i) tempCheck = i;
				if (tempCheck == null) return null;
				// Offsetting every single object in the layer except for the target one
				var offsetX = -target.width / 2 + target.x + 1;
				var offsetY = -target.height + target.y + 1;
				for (i in group.objects) {
					if (i != target) {
						i.x -= offsetX;
						i.y -= offsetY;
					}
				}
			default:
		}
		return null;
	}
}
