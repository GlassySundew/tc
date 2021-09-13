import h3d.scene.Mesh;
import differ.shapes.Polygon;
import dn.Process;
import en.items.Blueprint;
import en.objs.IsoTileSpr;
import en.player.Player;
import format.tmx.*;
import format.tmx.Data;
import h2d.Bitmap;
import h2d.Tile;
import h3d.Vector;
import h3d.col.Bounds;
import h3d.col.Point;
import h3d.mat.Texture;
import h3d.scene.Interactive;
import h3d.scene.Object;
import hxd.IndexBuffer;
import hxd.Res;
import tiled.TileLayerRenderer;
import tools.CPoint;
import tools.Save;
import ui.s3d.EventInteractive;
/**
	Level parses tmx entities maps, renders tie layers into mesh
**/
class Level extends dn.Process {
	public var game(get, never) : IGame;

	#if !headless
	function get_game() : IGame return (Game.inst != null) ? Game.inst : GameClient.inst;
	#elseif headless
	function get_game() : IGame return GameServer.inst;
	#end

	public static var inst : Level;

	// public var fx(get, never):Fx;

	public inline function getLayerByName( id : String ) return layersByName.get(id);

	public var wid(get, never) : Int;

	inline function get_wid() return M.ceil(data.width * data.tileWidth);

	public var hei(get, never) : Int;

	inline function get_hei() return M.ceil(data.height * data.tileHeight);

	//	public var lid(get, never):Int;
	var invalidated = true;

	public var sqlId : Null<Int>;
	public var lvlName : String;
	public var data : TmxMap;
	public var entities : Array<TmxObject> = [];
	public var walkable : Array<Polygon> = [];
	public var ground : Texture;
	public var obj : IsoTileSpr;

	var layersByName : Map<String, TmxLayer> = new Map();
	/**
		3d x coord of cursor
	**/
	public var cursX : Float;
	/**
		3d z coord of cursor
	**/
	public var cursY : Float;

	public var cursorInteract : Interactive;

	public function new( map : TmxMap ) {
		super(cast(game, Process));
		inst = this;
		// data = map;
		data = map;
		// new AxesHelper(Boot.inst.s3d);
		// new GridHelper(Boot.inst.s3d, 10, 10);
		#if !headless
		Boot.inst.engine.backgroundColor = data.backgroundColor;
		Boot.inst.s3d.camera.setFovX(70, Boot.inst.s3d.camera.screenRatio);
		#end

		for ( layer in data.layers ) {
			var name : String = 'null';
			switch( layer ) {
				case LObjectGroup(ol):
					name = ol.name;
					for ( obj in ol.objects ) {
						if ( ol.name == 'obstacles' ) {
							switch( obj.objectType ) {
								case OTPolygon(points):
									var pts = checkPolyClockwise(points);
									setWalkable(obj, pts);
								case OTRectangle:
									setWalkable(obj);
								default:
							}
						}
						if ( map.orientation == Isometric ) {
							// Если Entity никак не назван на карте - то ему присваивается имя его картинки без расширения
							if ( obj.name == "" ) {
								switch( obj.objectType ) {
									case OTTile(gid):
										var objGid = Tools.getTileByGid(data, gid);
										if ( objGid != null
											&& eregFileName.match(objGid.image.source) ) obj.name = eregFileName.matched(1);
									default:
								}
							}
							if ( ol.name == 'entities' ) entities.push(obj);
						}
					}
				case LTileLayer(tl):
					name = tl.name;
				default:
			}
			layersByName.set(name, layer);
		}
	}

	// function get_lid() {
	// 	var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
	// 	if ( !reg.match(Game.inst.lvlName) ) return -1; else
	// 		return Std.parseInt(reg.matched(1));
	// }

	override function onDispose() {
		super.onDispose();

		obj.remove();
		obj.primitive.dispose();
		cursorInteract.remove();
		ground.dispose();

		for ( i in walkable ) i.destroy();
		walkable = null;
		data = null;
		obj = null;
		entities = null;
		layersByName = null;
	}

	public function getEntities( id : String ) {
		var a = [];
		for ( e in entities ) if ( e.name == id ) a.push(e);
		return a;
	}

	public function getEntityPts( id : String ) {
		var a = [];
		for ( e in entities ) if ( e.name == id ) a.push(new CPoint((e.x), (e.y)));
		return a;
	}

	public function getEntityPt( id : String ) {
		for ( e in entities ) if ( e.name == id ) return new CPoint((e.x), (e.y));
		return null;
	}

	public function render() {
		var layerRenderer : LayerRender;

		invalidated = false;

		ground = new h3d.mat.Texture(data.width * data.tileWidth, data.height * data.tileHeight, [Target]);
		ground.filter = Nearest;

		obj = new IsoTileSpr(Tile.fromTexture(ground), false, Boot.inst.s3d);
		obj.alwaysSync = false;
		obj.rotate(0, 0, M.toRad(90));

		@:privateAccess obj.z += ground.height;
		obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		obj.material.mainPass.depth(false, LessEqual);
		obj.material.mainPass.setBlendMode(Alpha);

		for ( e in data.layers ) {
			switch( e ) {
				case LTileLayer(layer):
					if ( layer.visible #if !display_proto && layer.name != "proto" #end ) {
						layerRenderer = new LayerRender(data, layer);
						layerRenderer.render.g.drawTo(ground);
					}
				default:
			}
		}

		var imageLayer = layersByName.get("image");
		if ( imageLayer != null ) {
			switch( imageLayer ) {
				case LObjectGroup(ol):
					for ( obj in ol.objects ) {
						var isoX = 0., isoY = 0.;
						if ( data.orientation == Isometric ) {
							// все объекты в распаршенных слоях уже с конвертированными координатами
							// entities export lies ahead
							isoX = Level.inst.cartToIsoLocal(obj.x, obj.y).x;
							isoY = Level.inst.cartToIsoLocal(obj.x, obj.y).y;
						}

						switch( obj.objectType ) {
							case OTTile(gid):
								var bmp = new Bitmap(getTileFromSeparatedTsx(getTileSource(gid, Tools.getTilesetByGid(data, gid))));
								bmp.scaleX = obj.flippedVertically ? -1 : 1;
								bmp.x = isoX - obj.width / 2 * bmp.scaleX;
								bmp.y = hei - isoY - obj.height * (bmp.scaleX < 0 ? 0 : 1);
								bmp.drawTo(this.obj.material.texture);
							default:
						}
					}
				default:
			}
		}

		// чтобы получать 3d координаты курсора
		{
			var bounds = new Bounds();
			bounds.addPoint(new Point(0, 0, 0));
			bounds.addPoint(new Point(ground.width, 0, ground.height));

			cursorInteract = new h3d.scene.Interactive(bounds, Boot.inst.s3d);
			cursorInteract.priority = -10;
			cursorInteract.cursor = Default;
			cursorInteract.onMove = function ( e : hxd.Event ) {
				cursX = e.relX;
				cursY = e.relZ;
			}
		}

		#if colliders_debug
		for ( i in walkable ) {
			var pts : Array<Point> = [];
			for ( pt in i.vertices ) {
				pts.push(new Point(pt.x, 0, pt.y));
			}
			var idx = new IndexBuffer();
			for ( i in 1...pts.length - 1 ) {
				idx.push(0);
				idx.push(i);
				idx.push(i + 1);
			}

			var polyPrim = new h3d.prim.Polygon(pts, idx);
			polyPrim.addUVs();
			polyPrim.addNormals();

			var isoDebugMesh = new Mesh(polyPrim, obj);
			isoDebugMesh.rotate(0, M.toRad(180), M.toRad(90));
			isoDebugMesh.material.color.setColor(0x361bcc);
			isoDebugMesh.material.shadows = false;
			isoDebugMesh.material.mainPass.wireframe = true;
			isoDebugMesh.material.mainPass.depth(true, Less);

			isoDebugMesh.y = -i.x;
			isoDebugMesh.x = .25;
			isoDebugMesh.z = i.y - ground.height;
		}
		#end
	}

	public function setWalkable( poly : TmxObject, ?points : Array<Dynamic> ) { // setting obstacles as a differ polygon
		var vertices : Array<differ.math.Vector> = [];

		if ( points != null ) {
			checkPolyClockwise(points);
			for ( i in points ) vertices.push(new differ.math.Vector(cartToIso(i.x, i.y).x, cartToIso(i.x, i.y).y));
			walkable.push(new Polygon(cartToIsoLocal(poly.x, poly.y).x, cartToIsoLocal(poly.x, poly.y).y, vertices));
		} else if ( poly.objectType == OTRectangle ) {
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

		#if !headless
		if ( invalidated ) {
			render();
		}
		#end
	}

	public inline function cartToIsoLocal( x : Float, y : Float ) : Vector return new Vector(wid * .5 + cartToIso(x, y).x, hei - cartToIso(x, y).y);
}

class LayerRender extends h2d.Object {
	public var render : InternalRender;

	public function new( map : TmxMap, layer : TmxTileLayer ) {
		super();
		render = new InternalRender(map, layer);
		render.g = new h2d.Graphics();
		render.g.blendMode = Alpha;
		render.tex = new Texture(map.tileWidth * map.width, map.tileHeight * map.height, [Target]);

		render.render();
	}
}

private class InternalRender extends TileLayerRenderer {
	public var g : h2d.Graphics;

	public var tex : Texture;

	private var uv : Point = new Point();

	override function renderOrthoTile( x : Float, y : Float, tile : TmxTile, tileset : TmxTileset ) : Void {
		if ( tileset == null ) return;

		if ( tileset.image == null ) {
			renderOrthoTileFromImageColl(x, y, tile, tileset);
			return;
		}

		if ( tileset.tileOffset != null ) {
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

	function renderOrthoTileFromImageColl( x : Float, y : Float, tile : TmxTile, tileset : TmxTileset ) : Void {
		var sourceTile = getTileSource(tile.gid, tileset);
		var h2dTile = getTileFromSeparatedTsx(sourceTile);

		var bmp = new Bitmap(h2dTile);
		if ( tile.flippedDiagonally ) bmp.rotate(M.toRad(tile.flippedVertically ? -90 : 90));

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
		// tiles that contain *	 at the end of their file name as a slots for
		// structures; can be visible only when choosing place for structure to build

		// Это должно быть visible только тогда, когда у игрока в holdItem есть blueprint
		#if !headless
		if ( eregFileName.match(sourceTile.image.source)
			&& StringTools.endsWith(eregFileName.matched(1),
				"floor") ) Level.inst.game.structTiles.push(new StructTile(bmp.x + Level.inst.data.tileWidth / 2,
				Level.inst.ground.height - bmp.y - Level.inst.data.tileHeight / 2, Boot.inst.s3d));
		bmp.drawTo(tex);
		bmp.tile.dispose();
		bmp.remove();
		bmp = null;

		g.clear();
		g.drawTile(0, 0, Tile.fromTexture(tex));
		#end
	}

	override function renderIsoTiles( ox : Float, y : Float, tiles : Array<TmxTile>, width : Int, height : Int ) {
		var i : Int = 0;
		var ix : Int = 0;
		var iy : Int = 0;
		var x : Float = ox;
		var tset : TmxTileset;
		var tile : TmxTile;
		var hw : Float = map.tileWidth / 2;
		var hh : Float = map.tileHeight / 2;

		while( i < tiles.length ) {
			tile = tiles[i];
			renderIsoTile(x + ((ix - iy) * hw) + map.tileWidth * map.width / 2 - hw, y + (ix + iy) * hh, tile, Tools.getTilesetByGid(map, tile.gid));
			i++;
			if ( ++ix == width ) {
				ix = 0;
				iy++;
				// x = ox;
				// y += hh;
			} else {
				// x += hw;
			}
		}
	}
}

@:allow(Game, InternalRender)
class StructTile extends Object {
	public var taken : Bool = false;
	public var tile : EventInteractive;

	// Шаблон, из которого берётся коллайдер для tile
	public static var polyPrim : h3d.prim.Polygon = null;

	// Ortho size of tile
	public static var tileW : Int = 44;
	public static var tileH : Int = 20;

	override function new( x : Float, y : Float, ?parent : Object ) {
		super(parent);
		#if !headless
		if ( polyPrim == null ) initPolygon();
		tile = new EventInteractive(polyPrim.getCollider(), this);
		tile.rotate(-0.01, 0, hxd.Math.degToRad(180));

		tile.priority = -2;
		this.x = x;
		this.z = y;
		this.y = 0;

		tile.onMoveEvent.add(( event ) -> {
			if ( Player.inst != null && Player.inst.holdItem != null && Std.isOfType(Player.inst.holdItem, Blueprint) ) {
				cast(Player.inst.holdItem, Blueprint).onStructTileMove.dispatch(this);
			}
		});

		tile.onPushEvent.add(event -> {
			if ( Player.inst != null && Player.inst.holdItem != null && Std.isOfType(Player.inst.holdItem, Blueprint) ) {
				cast(Player.inst.holdItem, Blueprint).onStructurePlace.dispatch(this);
			}
		});
		#end
		#if debug
		// var prim = new h3d.prim.Cube();

		// // translate it so its center will be at the center of the cube
		// prim.translate(-0.5, -0.5, -0.5);

		// // unindex the faces to create hard edges normals
		// prim.unindex();

		// // add face normals
		// prim.addNormals();

		// // add texture coordinates
		// prim.addUVs();
		// var obj2 = new Mesh(prim, this);
		// obj2.scale(10);
		// // set the second cube color
		// obj2.material.color.setColor(0xFFB280);
		#end
	}

	public function initPolygon() {
		var pts : Array<Point> = [];
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
		polyPrim.translate(-tileW / 2, 0, tileH / 2);
	}
}
