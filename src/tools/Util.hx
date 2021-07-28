package tools;

import cdb.Types.TilePos;
import format.tmx.*;
import format.tmx.Data;
import format.tmx.Reader;
import h2d.Flow;
import h2d.Scene;
import h2d.Tile;
import h3d.Vector;
import hxbit.NetworkHost.NetworkClient;
import hxd.Res;
import hxd.res.Any;
import hxd.res.Loader;

using Util.LoaderExtender;

@:publicFields
@:expose
class Util {
	/**Regex to get class name provided by CompileTime libs, i.e. en.$Entity -> Entity **/
	static var eregCompTimeClass = ~/\$([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Regex to get '$this' class name i.e. en.Entity -> Entity **/
	static var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Регулярка чтобы взять из абсолютного пути название файла без расширения .png **/
	static var eregFileName = ~/\/([a-z_0-9]+)\./;

	inline static function loadTileFromCdb(cdbTile : TilePos) : Tile {
		return Res.loader.loadParentalFix(cdbTile.file).toTile().sub(cdbTile.x * cdbTile.size, cdbTile.y * cdbTile.size, cdbTile.size, cdbTile.size);
	}

	inline static function checkPolyClockwise(points : Array<Dynamic>) {
		var pts = points.copy();
		var sum = .0;
		for (i in 0...pts.length) {
			var actualItpp = (i >= pts.length - 1) ? 0 : i + 1;
			sum += (pts[actualItpp].x - pts[i].x) * (pts[actualItpp].y + pts[i].y);
		}
		sum < 0 ? pts.reverse() : {};
		return pts;
	}

	inline static function cartToIso(x : Float, y : Float) : Vector return new Vector((x - y), (x + y) / 2);

	inline static function screenToIsoX(globalX : Float, globalY : Float) {
		return globalX + globalY;
	}

	inline static function screenToIsoY(globalX : Float, globalY : Float) {
		return globalY - globalX / 2;
	}

	inline static function screenToIso(globalX : Float, globalY : Float) {
		return new Vector(screenToIsoX(globalX, globalY), screenToIsoY(globalX, globalY));
	}

	public static var wScaled(get, never) : Int;

	inline static function get_wScaled() return Std.int(Boot.inst.s2d.width / Const.SCALE);

	public static var hScaled(get, never) : Int;

	inline static function get_hScaled() return Std.int(Boot.inst.s2d.height / Const.SCALE);

	inline static function getTileFromSeparatedTsx(tile : TmxTilesetTile) : Tile {
		// #if pak
		return Res.loader.loadParentalFix(Const.LEVELS_PATH + tile.image.source).toTile();
		// #else
		// return Res.loader.load(Const.LEVELS_PATH + tile.image.source).toTile();
		// #end
	}

	inline static function getTileSource(gid : Int, tileset : TmxTileset) : TmxTilesetTile {
		var fixedGId = gid - tileset.firstGID;
		// фикс на непоследовательные id тайлов
		for (i in 0...tileset.tiles.length) if ( tileset.tiles[i].id == fixedGId && fixedGId > i ) while( fixedGId > i )
			fixedGId--;
		return (tileset.tiles[fixedGId]);
	}

	inline static function getTsx(tsx : Map<String, TmxTileset>, r : Reader) : String -> TmxTileset {
		return (name : String) -> {
			var cached : TmxTileset = tsx.get(name);
			if ( cached != null ) return cached;
			cached = r.readTSX(Xml.parse(Res.loader.loadParentalFix(Const.LEVELS_PATH + name).entry.getText()));
			tsx.set(name, cached);
			return cached;
		}
	}

	inline static function resolveMap(lvlName : String) {
		var tsx = new Map();
		var r = new Reader();
		r.resolveTSX = getTsx(tsx, r);
		var tmx = r.read(Xml.parse(Res.loader.load(Const.LEVELS_PATH + lvlName + (StringTools.endsWith(lvlName, ".tmx") ? "" : ".tmx")).entry.getText()));
		return tmx;
	}

	inline static function getProjectedDifferPolygonRect(?obj : TmxObject, points : Array<TmxPoint>) : Vector {
		var pts = checkPolyClockwise(points);
		var verts : Array<Vector> = [];
		for (i in pts) verts.push(new Vector((i.x), (-i.y)));

		var yArr = verts.copy();
		yArr.sort(function(a, b) return (a.y < b.y) ? -1 : ((a.y > b.y) ? 1 : 0));
		var xArr = verts.copy();
		xArr.sort(function(a, b) return (a.x < b.x) ? -1 : ((a.x > b.x) ? 1 : 0));

		// xCent и yCent - половины ширины и высоты неповёрнутого полигона соответственно
		var xCent : Float = M.round((xArr[xArr.length - 1].x + xArr[0].x) * .5);
		var yCent : Float = -M.round((yArr[yArr.length - 1].y + yArr[0].y) * .5);

		// c - радиус от начальной точки поли до центра поли
		var c = Math.sqrt(M.pow(xCent, 2) + M.pow(yCent, 2));
		// alpha - угол между начальной точкой неповёрнутого полигона и центром полигона
		var alpha = Math.atan(yCent / xCent);

		// xCent и yCent в данный момент - проекции отрезка, соединяющего начальную точку полигона и центр полигона на оси x и y соответственно
		if ( obj != null ) {
			yCent = -c * (Math.sin(M.toRad(-obj.rotation) - alpha));
			xCent = c * (Math.cos(M.toRad(-obj.rotation) - alpha));
		}
		return new Vector(xCent, yCent);
	}

	static var entParent : Scene;

	public static var uiConf : Map<String, TmxLayer>;

	public static var inventoryCoordRatio : Vector = new Vector(-1, -1);
	
}

class ReverseIterator {
	var end:Int;
	var i:Int;
  
	public inline function new(start:Int, end:Int) {
	  this.i = start;
	  this.end = end;
	}
  
	public inline function hasNext() return i >= end;
	public inline function next() return i--;
  }
  
  class ReverseArrayKeyValueIterator<T> {
    final arr:Array<T>;
    var i:Int;

    public inline function new(arr:Array<T>) {
        this.arr = arr;
        this.i = this.arr.length - 1; 
    }

    public inline function hasNext() return i > -1;
    public inline function next() {
        return {value: arr[i], key: i--};
    }

    public static inline function reversedKeyValues<T>(arr:Array<T>) {
        return new ReverseArrayKeyValueIterator(arr);
    }
}
class TmxMapExtender {
	public static function getLayersByName(tmxMap : TmxMap) : Map<String, TmxLayer> {
		var map : Map<String, TmxLayer> = [];
		for (i in tmxMap.layers) {
			var name : String = 'null';
			switch( i ) {
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
	public static function getObjectByName(tmxLayer : TmxLayer, name : String) : TmxObject {
		switch( tmxLayer ) {
			case LObjectGroup(group):
				for (i in group.objects) {
					if ( i.name == name ) return i;
				}
			default:
		}
		return null;
	}
	/** Localises all objects of this layer to be local to certain object of this layer **/
	public static function localBy(tmxLayer : TmxLayer, target : TmxObject) {
		switch( tmxLayer ) {
			case LObjectGroup(group):
				// Checking if the object belongs to the layer
				var tempCheck = null;
				for (i in group.objects) if ( target == i ) tempCheck = i;
				if ( tempCheck == null ) return null;
				// Offsetting every single object in the layer except for the target one
				var offsetX = -target.width / 2 + target.x + 1;
				var offsetY = -target.height + target.y + 1;
				for (i in group.objects) {
					if ( i != target ) {
						i.x -= offsetX;
						i.y -= offsetY;
						switch( i.objectType ) {
							case OTTile(gid):
								i.x -= i.width / 2 - 1;
								i.y -= i.height - 1;
							default:
						}
					}
				}
			default:
		}
		return null;
	}
}

class SocketHostExtender {
	public static function sendTypedMessage(sHost : hxd.net.SocketHost, msg : Message, ?to : NetworkClient) sHost.sendMessage(msg, to);

	public static dynamic function onTypedMessage(sHost : hxd.net.SocketHost, onMessage : NetworkClient -> Message -> Void) {
		sHost.onMessage = onMessage;
	}
}

class LoaderExtender {
	// unsafe crutch, removes ../ from path, use only if you you have link to the folder upper in dir
	public static function loadParentalFix(loader : Loader, path : String) : Any {
		while( StringTools.contains(path, "../") )path = StringTools.replace(path, "../", "");
		return new Any(loader, loader.fs.get(path));
	}
}

class FlowExtender {
	public static function center(flow : Flow) {
		flow.paddingLeft = -flow.innerWidth >> 1;
		flow.paddingTop = -flow.innerHeight >> 1;
	}
}
