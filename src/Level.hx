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

class Level extends dn.Process {
	public var game(get, never):Game;

	inline function get_game()
		return Game.inst;

	public static var inst:Level;

	// public var fx(get, never):Fx;
	var layersByName:Map<String, TmxLayer> = new Map();

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
	public var ground:Texture;
	public var obj:Mesh;

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
								checkPolyClockwise(points);
								if (ol.name == 'walls') setWalkable(obj, points);
							case OTRectangle:
								if (ol.name == 'walls') setWalkable(obj);

							default:
						}
						// все объекты в распаршенных слоях уже с конвертированными координатами
						// entities export lies ahead
						var isoX = cartToIsoLocal(obj.x, obj.y).x;
						var isoY = cartToIsoLocal(obj.x, obj.y).y;
						obj.x = isoX / Const.GRID_WIDTH;
						obj.y = isoY / Const.GRID_WIDTH;
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

		data = null;
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
						new LayerRender(data, layer).render.g.drawTo(obj.material.texture);
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
								var bmp = new Bitmap(getTileFromSeparatedTsx(gid, Tools.getTilesetByGid(data, gid)));
								bmp.scaleX = obj.flippedVertically ? 1:-1;
								bmp.x = obj.x * Const.GRID_WIDTH - obj.width / 2;
								bmp.y = hei - obj.y * Const.GRID_WIDTH - obj.height;
								bmp.drawTo(this.obj.material.texture);
							default:
						}
					}
				default:
			}
		}

		// obj.material.mainPass.setPassName("alpha");
		// obj.visible = false;
		obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		obj.material.mainPass.depth(false, LessEqual);
	}

	public function setWalkable(poly:TmxObject, ?points:Array<TmxPoint>) { // setting obstacles as a differ polygon
		var vertices:Array<differ.math.Vector> = [];
		if (points != null) {
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
	}

	function renderOrthoTileFromImageColl(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void {
		// var imageSource;
		// var gid = tile.gid - tileset.firstGID;
		// // fix for offseting ids to right order
		// for (i in 0...tileset.tiles.length)
		// 	if (tileset.tiles[i].id == gid && gid > i)
		// 		while (gid > i)
		// 			gid--;
		// // while (tileset.tiles[gid - tileset.firstGID] == null) // making tiles' ids persistent
		// // 	gid--;
		// imageSource = tileset.tiles[gid];
		// var h2dTile = Res.loader.load(Const.LEVELS_PATH + imageSource.image.source).toTile();

		var h2dTile = getTileFromSeparatedTsx(tile.gid, tileset);
		var bmp = new Bitmap(h2dTile);
		if (tile.flippedDiagonally) {
			// h2dTile.setCenterRatio(.5, .5);
			bmp.rotate(M.toRad(tile.flippedVertically ? -90 : 90));
		}

		var scaleX = (tile.flippedHorizontally && !tile.flippedDiagonally) ? -1 : 1;
		var scaleY = (tile.flippedVertically && !tile.flippedDiagonally) ? -1 : 1;

		bmp.scaleX = scaleX;
		bmp.scaleY = scaleY;

		bmp.x = x + (scaleX > 0 ? 0 : h2dTile.width) + (tile.flippedDiagonally ? (tile.flippedHorizontally ? h2dTile.height : 0) : 0);
		// bmp.y = y - h2dTile.height + map.tileHeight + (scaleY == 1 ? 0 : h2dTile.height) + layer.offsetY;
		bmp.y = y
			- h2dTile.height
			+ map.tileHeight
			+ (scaleY > 0 ? 0 : h2dTile.height)
			- layer.offsetX
			+ layer.offsetY
			+ (tile.flippedDiagonally ? (tile.flippedVertically ? h2dTile.height : -h2dTile.width + h2dTile.height) : 0);

		bmp.drawTo(tex);
		g.drawTile(0, 0, Tile.fromTexture(tex));
		g.endFill();
	}
}
