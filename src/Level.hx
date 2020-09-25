import ui.EventInteractive;
import hxd.IndexBuffer;
import h3d.scene.Interactive;
import h3d.col.Bounds;
import en.player.Player;
import h3d.prim.Grid;
import h3d.mat.Material;
import ch3.prim.PlanePrim;
import differ.shapes.Polygon;
import h3d.scene.Mesh;
import h3d.Vector;
import h2d.Tile;
import h2d.Bitmap;
import hxd.Res;
import h3d.col.Point;
import h3d.mat.Texture;
import tiled.TileLayerRenderer;
import h3d.scene.Object;
import h3d.scene.CameraController;
import tools.CPoint;
import format.tmx.*;
import format.tmx.Data;
import tools.Util.*;

/**
	Level parses tmx entities maps, renders tile layers into mesh
**/
class Level extends dn.Process {
	public var game(get, never):Game;

	inline function get_game()
		return Game.inst;

	public static var inst:Level;

	// public var fx(get, never):Fx;

	public inline function getLayerByName(id:String)
		return layersByName.get(id);

	public var wid(get, never):Int;

	inline function get_wid()
		return M.ceil(data.width * data.tileWidth);

	public var hei(get, never):Int;

	inline function get_hei()
		return M.ceil(data.height * data.tileHeight);

	//	public var lid(get, never):Int;
	var invalidatedColls = true;
	var invalidated = true;

	public var data:TmxMap;
	public var entities:Array<TmxObject> = [];
	public var walkable:Array<Polygon> = [];
	public var structTiles:Array<StructTile> = [];
	public var ground:Texture;
	public var obj:Mesh;

	var layersByName:Map<String, TmxLayer> = new Map();

	/**
		3d x coord of cursor
	**/
	public var cursX:Float;

	/**
		3d z coord of cursor
	**/
	public var cursY:Float;

	public var cursorInteract:Interactive;

	public function new(map:TmxMap) {
		super(Game.inst);
		inst = this;
		data = map;

		// new AxesHelper(Boot.inst.s3d);
		// new GridHelper(Boot.inst.s3d, 10, 10);

		Boot.inst.engine.backgroundColor = data.backgroundColor;
		Boot.inst.s3d.camera.setFovX(70, Boot.inst.s3d.camera.screenRatio);

		for (layer in data.layers) {
			var name:String = 'null';
			switch (layer) {
				case LObjectGroup(ol):
					name = ol.name;
					for (obj in ol.objects) {
						switch (obj.objectType) {
							case OTPolygon(points):
								var pts = checkPolyClockwise(points);
								pts.reverse();
								if (ol.name == 'walls') setWalkable(obj, pts);
							case OTRectangle:
								if (ol.name == 'walls') setWalkable(obj);

							default:
						}
						// все объекты в распаршенных слоях уже с конвертированными координатами
						// entities export lies ahead
						var isoX = cartToIsoLocal(obj.x, obj.y).x;
						var isoY = cartToIsoLocal(obj.x, obj.y).y;

						if (obj.flippedVertically)
							isoY -= obj.height;

						obj.x = isoX / Const.GRID_WIDTH;
						obj.y = isoY / Const.GRID_WIDTH;

						// Если Entity никак не назван на карте - то ему присваивается имя его картинки без расширения
						if (obj.name == "") {
							switch (obj.objectType) {
								case OTTile(gid):
									var ereg = ~/\/([a-z0-9_\.-]+)\./;
									if (ereg.match(Tools.getTileByGid(data, gid).image.source)) obj.name = ereg.matched(1);
								default:
							}
						}

						if (ol.name == 'entities')
							entities.push(obj);
					}
				case LTileLayer(tl):
					name = tl.name;
				default:
			}
			layersByName.set(name, layer);
		}
	}

	function get_lid() {
		var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
		if (!reg.match(Game.inst.lvlName))
			return -1;
		else
			return Std.parseInt(reg.matched(1));
	}

	override function onDispose() {
		super.onDispose();
		obj.remove();
		obj.primitive.dispose();
		cursorInteract.remove();
		ground.dispose();

		for (i in walkable)
			i.destroy();
		walkable = null;
		data = null;
		obj = null;
		entities = null;
		layersByName = null;
	}

	public function getEntities(id:String) {
		var a = [];
		for (e in entities)
			if (e.name == id)
				a.push(e);
		return a;
	}

	public function getEntityPts(id:String) {
		var a = [];
		for (e in entities)
			if (e.name == id)
				a.push(new CPoint((e.x), (e.y)));
		return a;
	}

	public function getEntityPt(id:String) {
		for (e in entities)
			if (e.name == id)
				return new CPoint((e.x), (e.y));
		return null;
	}

	public function render() {
		var layerRenderer:LayerRender;

		invalidated = false;

		ground = new h3d.mat.Texture(data.width * data.tileWidth, data.height * data.tileHeight, [Target, WasCleared]);
		ground.filter = Nearest;
		var prim = new PlanePrim(ground.width, ground.height, -ground.width, -ground.height, Y);

		obj = new Mesh(prim, Material.create(ground), Boot.inst.s3d);
		obj.material.mainPass.setBlendMode(AlphaAdd);
		for (e in data.layers) {
			switch (e) {
				case LTileLayer(layer):
					if (layer.visible) {
						layerRenderer = new LayerRender(data, layer);
						layerRenderer.render.g.drawTo(obj.material.texture);
					}
				default:
			}
		}

		var imageLayer = layersByName.get("image");
		if (imageLayer != null) {
			switch (imageLayer) {
				case LObjectGroup(ol):
					for (obj in ol.objects) {
						switch (obj.objectType) {
							case OTTile(gid):
								var bmp = new Bitmap(getTileFromSeparatedTsx(getTileSource(gid, Tools.getTilesetByGid(data, gid))));
								bmp.scaleX = obj.flippedVertically ? -1 : 1;
								bmp.x = obj.x * Const.GRID_WIDTH - obj.width / 2 * bmp.scaleX;
								bmp.y = hei - obj.y * Const.GRID_WIDTH - obj.height * (bmp.scaleX < 0 ? 0 : 1);
								bmp.drawTo(this.obj.material.texture);
							default:
						}
					}
				default:
			}
		}

		obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		obj.material.mainPass.depth(false, LessEqual);

		// Хуйня чтобы получать 3d координаты курсора
		{
			var bounds = new Bounds();
			bounds.addPoint(new Point(0, 0, 0));
			bounds.addPoint(new Point(ground.width, 0, ground.height));

			cursorInteract = new h3d.scene.Interactive(bounds, obj);
			cursorInteract.priority = -10;
			cursorInteract.cursor = Default;
			cursorInteract.onMove = function(e:hxd.Event) {
				cursX = e.relX;
				cursY = e.relZ;
			}
		}
	}

	public function setWalkable(poly:TmxObject, ?points:Array<Dynamic>) { // setting obstacles as a differ polygon
		var vertices:Array<differ.math.Vector> = [];
		if (points != null) {
			points.reverse();
			for (i in points)
				vertices.push(new differ.math.Vector(cartToIso(i.x, i.y).x, cartToIso(i.x, i.y).y));
			walkable.push(new Polygon(cartToIsoLocal(poly.x, poly.y).x, cartToIsoLocal(poly.x, poly.y).y, vertices));
		} else if (poly.objectType == OTRectangle) {
			vertices.push(new differ.math.Vector(cartToIso(poly.width, 0).x, cartToIso(poly.width, 0).y));
			vertices.push(new differ.math.Vector(cartToIso(poly.width, poly.height).x, cartToIso(poly.width, poly.height).y));
			vertices.push(new differ.math.Vector(cartToIso(0, poly.height).x, cartToIso(0, poly.height).y));
			vertices.push(new differ.math.Vector(0, 0));

			walkable.push(new Polygon(cartToIsoLocal(poly.x, poly.y).x, cartToIsoLocal(poly.x, poly.y).y, vertices));
		}
		walkable[walkable.length - 1].scaleY = -1;
	}

	override function postUpdate() {
		super.postUpdate();

		if (invalidated) {
			render();
		}
	}

	public inline function cartToIsoLocal(x:Float, y:Float):Vector
		return new Vector(wid * .5 + cartToIso(x, y).x, hei - cartToIso(x, y).y);
}

class LayerRender extends h2d.Object {
	public var render:InternalRender;

	public function new(map:TmxMap, layer:TmxTileLayer) {
		super();
		render = new InternalRender(map, layer);
		render.g = new h2d.Graphics();
		render.g.blendMode = Alpha;
		render.tex = new Texture(map.tileWidth * map.width, map.tileHeight * map.height, [Target]);
		render.render();
	}
}

private class InternalRender extends TileLayerRenderer {
	public var g:h2d.Graphics;

	public var tex:Texture;

	private var uv:Point = new Point();

	override function renderOrthoTile(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void {
		if (tileset == null)
			return;

		if (tileset.image == null) {
			renderOrthoTileFromImageColl(x, y, tile, tileset);
			return;
		}

		if (tileset.tileOffset != null) {
			x += tileset.tileOffset.x;
			y += tileset.tileOffset.y;
		}
		var scaleX = tile.flippedHorizontally ? -1 : 1;
		var scaleY = tile.flippedVertically ? -1 : 1;
		Tools.getTileUVByLidUnsafe(tileset, tile.gid - tileset.firstGID, uv);
		var h2dTile = Res.loader.load(Const.LEVELS_PATH + tileset.image.source).toTile();
		g.beginTileFill(x
			- uv.x
			+ (scaleX == 1 ? 0 : map.tileWidth)
			+ layer.offsetX,
			y
			- uv.y * scaleY
			+ map.tileHeight
			- tileset.tileHeight / (scaleY == 1 ? 1 : 1)
			+ layer.offsetY, scaleX, scaleY, h2dTile);
		g.drawRect(x, y + map.tileHeight - tileset.tileHeight, tileset.tileWidth, tileset.tileHeight);
		g.endFill();

		h2dTile.dispose();
		h2dTile = null;
	}

	function renderOrthoTileFromImageColl(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void {
		var sourceTile = getTileSource(tile.gid, tileset);
		var h2dTile = getTileFromSeparatedTsx(sourceTile);

		var bmp = new Bitmap(h2dTile);
		if (tile.flippedDiagonally)
			bmp.rotate(M.toRad(tile.flippedVertically ? -90 : 90));

		var scaleX = (tile.flippedHorizontally && !tile.flippedDiagonally) ? -1 : 1;
		var scaleY = (tile.flippedVertically && !tile.flippedDiagonally) ? -1 : 1;

		bmp.scaleX = scaleX;
		bmp.scaleY = scaleY;

		bmp.x = x + (scaleX > 0 ? 0 : h2dTile.width) + (tile.flippedDiagonally ? (tile.flippedHorizontally ? h2dTile.height : 0) : 0);
		bmp.y = y
			- h2dTile.height
			+ map.tileHeight
			+ (scaleY > 0 ? 0 : h2dTile.height)
			- layer.offsetX
			+ layer.offsetY
			+ (tile.flippedDiagonally ? (tile.flippedVertically ? h2dTile.height : -h2dTile.width + h2dTile.height) : 0);

		// Creating isometric(rombic) h3d.scene.Interactive on top of separated
		// tiles that contain *floor at the end of their file name as a slots for structures,
		var ereg = ~/\/([a-z_0-9]+)\./; // regexp to take picture name between last / and . from picture path
		if (ereg.match(sourceTile.image.source) && StringTools.endsWith(ereg.matched(1), "floor"))
			Level.inst.structTiles.push(new StructTile(bmp.x, bmp.y, Level.inst.obj));
		bmp.drawTo(tex);
		bmp.tile.dispose();
		bmp.remove();
		bmp = null;

		g.drawTile(0, 0, Tile.fromTexture(tex));
		g.endFill();
	}
}

class StructTile extends Object {
	public var taken:Bool = false;
	public var tile:EventInteractive;

	// Шаблон, из которого берётся коллайдер для {this.tile}
	static var polyPrim:h3d.prim.Polygon = null;

	// Ortho size of tile
	var tileW:Int = 48;
	var tileH:Int = 24;

	override public function new(x:Float, y:Float, ?parent:Object) {
		super(parent);
		if (polyPrim == null)
			initPolygon();
		tile = new EventInteractive(polyPrim.getCollider(), this);
		tile.rotate(-0.01, 0, hxd.Math.degToRad(90));

		tile.priority = 2;
		this.x = x;
		this.z = y;
		this.y = 1;
	}

	function initPolygon() {
		var pts:Array<Point> = [];
		pts.push(new Point(tileW / 2, 0, 0));
		pts.push(new Point(0, 0, -tileH / 2));
		pts.push(new Point(tileW / 2, 0, -tileH));
		pts.push(new Point(tileW, 0, -tileH / 2));

		var idx = new IndexBuffer();
		idx.push(0);
		idx.push(1);
		idx.push(2);

		idx.push(0);
		idx.push(2);
		idx.push(3);
		polyPrim = new h3d.prim.Polygon(pts, idx);
	}
}
