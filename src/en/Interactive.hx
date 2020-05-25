package en;

import h3d.shader.Blur;
import h2d.Tile;
import h2d.Bitmap;
import hxGeomAlgo.IsoContours;
import hxGeomAlgo.PolyTools.Tri;
import hxGeomAlgo.HxPoint;
import h3d.prim.Polygon;
import h3d.scene.Mesh;
import hxd.IndexBuffer;
import h3d.col.Point;
import h2d.filter.Glow;
import h3d.Matrix;
import format.tmx.Tools;
import h2d.filter.Filter;
import h3d.Vector;
import hxd.Key;
import h3d.scene.Interactive;
import format.tmx.Data.TmxObject;
import tools.Util.*;
import hxGeomAlgo.MarchingSquares;
import hxPixels.Pixels;
import hxGeomAlgo.EarCut;

/**
	An interactive entity
**/
class Interactive extends Entity {
	public var interact:h3d.scene.Interactive;

	var filter:Glow;
	var polyPrim:Polygon;
	var idx:IndexBuffer;
	var translatedPoints:Array<Point> = [];
	var polygonized:Array<Tri>;
	var points:Array<HxPoint>;

	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		super(x, z, tmxObj);

		var pixels = Pixels.fromBytes(tex.capturePixels().bytes, Std.int(spr.tile.width), Std.int(spr.tile.height));
		points = new MarchingSquares(pixels).march();
		polygonized = (EarCut.triangulate(points));

		for (i in polygonized) {
			for (j in i) {
				translatedPoints.push(new Point(j.x, 0, j.y));
			}
		}

		idx = new IndexBuffer();
		for (poly in 0...polygonized.length) {
			idx.push(findVertexNumberInArray(polygonized[poly][0], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][1], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][2], translatedPoints));
		}

		polyPrim = new Polygon(translatedPoints, idx);
		interact = new h3d.scene.Interactive(polyPrim.getCollider(), Boot.inst.s3d);
		interact.rotate(-0.1, hxd.Math.degToRad(180), hxd.Math.degToRad(180));
		var highlightColor:String;
		// if (tmxObj != null)
		highlightColor = tmxTile.properties.get("highlight");
		filter = new h2d.filter.Glow(Color.hexToInt(highlightColor == null ? "ffffffff" : highlightColor), 1.2, 4, .8, 1.5, true);
		interact.onOver = function(e:hxd.Event) {
			bmp.filter = filter;
			filter.enable = true;
			// var bmp = new Bitmap(spr.tile);
			// spr.filter = filter;
			// spr.tile.switchTexture(Tile.fromTexture(bmp.tile.getTexture()));
		};

		interact.onMove = interact.onCheck = function(e:hxd.Event) {};
		interact.onOut = function(e:hxd.Event) {
			filter.enable = false;
		};
		interact.onClick = function(e:hxd.Event) {};
	}

	override function postUpdate() {
		super.postUpdate();
		if (mesh != null)
			interact.setPosition(mesh.x - spr.tile.width * spr.pivot.centerFactorX, mesh.y, mesh.z + spr.tile.height * spr.pivot.centerFactorY);
		// deactivate interactive if inventory is opened
		interact.visible = !player.inventory.base.visible;
	}

	function findVertexNumberInArray(point:Dynamic, findIn:Array<Point>):Int {
		for (pts in 0...findIn.length) {
			if (point.x == findIn[pts].x && point.y == findIn[pts].z)
				return pts;
		}
		throw "Not part of this array";
	}
}
