import differ.shapes.Polygon;
import h3d.prim.PlanePrim;
import h3d.scene.TileSprite;
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
	public var walkable:Polygon;
	public var ground:Texture;
	public var obj:Mesh;

	public function new(map:TmxMap) {
		super(Game.inst);
		inst = this;
		data = map;

		// new AxesHelper(Boot.inst.s3d);
		// new GridHelper(Boot.inst.s3d, 10, 10);

		Boot.inst.engine.backgroundColor = data.backgroundColor;
		// Boot.inst.s3d.camera.setFovX(70, Boot.inst.s3d.camera.screenRatio);

		for (layer in data.layers) {
			var name:String = 'null';
			switch (layer) {
				case LObjectGroup(ol):
					name = ol.name;
					for (obj in ol.objects) {
						switch (obj.objectType) {
							case OTPolygon(points):
								if (ol.name == 'hitboxes' && obj.name == 'walkable')
									setWalkable(obj, points);
							default:
						}

						// entities export lies ahead
						var isoX = cart_to_iso_abs(obj.x, obj.y).x;
						var isoY = cart_to_iso_abs(obj.x, obj.y).y;

						obj.x = isoX / Const.GRID_WIDTH;
						obj.y = isoY / Const.GRID_WIDTH;
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

	// function get_lid() {
	// 	// var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
	// 	// if (!reg.match(Game.inst.lvlName))
	// 	// 	return -1;
	// 	// else
	// 	// 	return Std.parseInt(reg.matched(1));
	// }

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

		ground = new h3d.mat.Texture(data.width * data.tileWidth, data.height * data.tileHeight, [Target]);
		ground.filter = Nearest;

		for (e in data.layers) {
			switch (e) {
				case LTileLayer(layer):
					new LayerRender(data, layer).render.g.drawTo(ground);
				default:
			}
		}

		var prim = new PlanePrim(ground.width, ground.height, -ground.width, -ground.height, Y);
		obj = new Mesh(prim, h3d.mat.Material.create(ground), Boot.inst.s3d);
		obj.material.mainPass.setBlendMode(Alpha);
		// obj.material.mainPass.setPassName("alpha");
		// obj.visible = false;
		// obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		obj.material.mainPass.depth(false, LessEqual);
	}

	public function setWalkable(poly:TmxObject, points:Array<TmxPoint>) { // setting walk area as a differ polygon(prob a shitty idea, but idk)
		var vertices:Array<differ.math.Vector> = [];
		trace(poly.x, poly.y);
		for (i in points)
			vertices.push(new differ.math.Vector(cart_to_iso(i.x, i.y).x, cart_to_iso(i.x, i.y).y));
		vertices.reverse();
		walkable = new Polygon(cart_to_iso_abs(poly.x, poly.y).x, cart_to_iso_abs(poly.x, poly.y).y, vertices);
		walkable.scaleY = -1;
	}

	override function postUpdate() {
		super.postUpdate();

		if (invalidated) {
			render();
		}
	}

	inline function cart_to_iso(x:Float, y:Float):Vector
		return new Vector((x - y), (x + y) / 2);

	inline function cart_to_iso_abs(x:Float, y:Float):Vector
		return new Vector(wid * .5 + cart_to_iso(x, y).x, hei - cart_to_iso(x, y).y);
}

class LayerRender extends h2d.Object {
	public var render:InternalRender;

	public function new(map:TmxMap, layer:TmxTileLayer) {
		super();
		render = new InternalRender(map, layer);
		render.g = new h2d.Graphics();
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

		if (tileset.tileOffset != null) {
			x += tileset.tileOffset.x;
			y += tileset.tileOffset.y;
		}
		if (tileset.image == null) {
			renderOrthoTileFromImageColl(x, y, tile, tileset);

			return;
		}

		var scaleX = tile.flippedHorizontally ? -1 : 1;
		var scaleY = tile.flippedVertically ? -1 : 1;
		Tools.getTileUVByLidUnsafe(tileset, tile.gid - tileset.firstGID, uv);
		var h2dTile = Res.loader.load("tiled/" + tileset.image.source).toTile();
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
		var h2dTile = Res.loader.load("tiled/" + tileset.tiles[tile.gid - tileset.firstGID].image.source).toTile();
		var bmp = new Bitmap(h2dTile);
		var scaleX = tile.flippedHorizontally ? -1 : 1;
		var scaleY = tile.flippedVertically ? -1 : 1;
		bmp.scaleX = scaleX;
		bmp.scaleY = scaleY;

		bmp.x = x + (scaleX == 1 ? 2 : map.tileWidth) + layer.offsetX;
		bmp.y = y - h2dTile.height + map.tileHeight + (scaleY == 1 ? 0 : h2dTile.height) + layer.offsetY;

		bmp.drawTo(tex);
		g.drawTile(0, 0, Tile.fromTexture(tex));
		g.endFill();
	}
}

class GridHelper extends h3d.scene.Graphics {
	public function new(?parent:Object, size = 10.0, divisions = 10, color1 = 0x444444, color2 = 0x888888, lineWidth = 1.0) {
		super(parent);

		material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");

		lineShader.width = lineWidth;

		var hsize = size / 2;
		var csize = size / divisions;
		var center = divisions / 2;
		for (i in 0...divisions + 1) {
			var p = i * csize;
			setColor((i != 0 && i != divisions && i % center == 0) ? color2 : color1);
			moveTo(-hsize + p, -hsize, 0);
			lineTo(-hsize + p, -hsize + size, 0);
			moveTo(-hsize, -hsize + p, 0);
			lineTo(-hsize + size, -hsize + p, 0);
		}
	}
}

class PointLightHelper extends h3d.scene.Mesh {
	public function new(light:h3d.scene.fwd.PointLight, sphereSize = 0.5) {
		var prim = new h3d.prim.Sphere(sphereSize, 4, 2);
		prim.addNormals();
		prim.addUVs();
		super(prim, light);
		material.color = light.color;
		material.mainPass.wireframe = true;
	}
}

class InstancedOffsetShader extends hxsl.Shader {
	static var SRC = {
		@:import h3d.shader.BaseMesh;
		@perInstance(2) @input var offset:Vec2;
		function vertex() {
			transformedPosition.xy += offset;
			transformedPosition.xy += float(instanceID & 1) * vec2(0.2, 0.1);
			transformedPosition.z += float(instanceID) * 0.01;
			pixelColor.r = float(instanceID) / 16.;
			pixelColor.g = float(vertexID) / 8.;
		}
	};
}
