package en;

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
	var polyMesh:Mesh;

	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		super(x, z, tmxObj);

		var pixels = Pixels.fromBytes(tex.capturePixels().bytes, Std.int(spr.tile.width), Std.int(spr.tile.height));
		var points = new MarchingSquares(pixels).march();
		var polygonized = /*EarCut.polygonize*/ (EarCut.triangulate(points));
		var translatedPoints:Array<Point> = [];

		for (i in polygonized) {
			for (j in i) {
				trace(j.x, j.y);
				translatedPoints.push(new Point(j.x, 0, j.y));
			}
			trace("___________");
		}
		// translatedPoints.reverse();
		// for (i in 0...polygonized.length) {
		// 	for (j in 0...polygonized[i].length) {
		// 		translatedPoints[i] = new Point(polygonized[i][j].x, 0, polygonized[i][j].y);
		// 	}
		// }

		var idx = new IndexBuffer();
		for (poly in 0...polygonized.length) {
			// if (polygonized[poly].length > 3) {
			idx.push(findVertexNumberInArray(polygonized[poly][0], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][1], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][2], translatedPoints));
			// }
		}
		// for (poly in 0...polygonized.length) {
		// 	var p0 = 0, p1 = 0, p2 = 0;
		// 	for (polyPts in 0...polygonized[pyly].length)
		// 		for (pt in 0...points.length) {
		// 			if (polygonized[poly][pt] ==)
		// 		}
		// 	idx.push(p0);
		// 	idx.push(p1);
		// 	idx.push(p2);
		// }
		var polyPrim = new Polygon(translatedPoints, idx);

		interact = new h3d.scene.Interactive(polyPrim.getCollider(), Boot.inst.s3d);

		interact.rotate(0, hxd.Math.degToRad(180), hxd.Math.degToRad(180));
		// interact.x -= spr.tile.width * .5;
		var highlightColor = tmxTile.properties.get("highlight");

		interact.onOver = function(e:hxd.Event) {
			filter = new h2d.filter.Glow(Color.hexToInt(highlightColor == null ? "ffffffff" : highlightColor), 1.2, 4, .8, 1.5, true);
			bmp.filter = filter;
		};

		interact.onMove = interact.onCheck = function(e:hxd.Event) {
			trace(e.relX, e.relY, e.relZ, interact.x, interact.y, interact.z);
		};
		interact.onOut = function(e:hxd.Event) {
			// filter.
			bmp.filter = null;
		};
	}

	override function postUpdate() {
		super.postUpdate();
		interact.setPosition(mesh.x - spr.tile.width * mesh.originMX, mesh.y, mesh.z + spr.tile.height * mesh.originMY);
		// mesh.z += 1 / Camera.ppu;
		if (Key.isPressed(Key.J))
			interact.x--;
		if (Key.isPressed(Key.L)) {
			interact.x++;
			interact.y--;
		}
		if (Key.isPressed(Key.I))
			interact.z--;
		if (Key.isPressed(Key.K))
			interact.z++;
	}

	function findVertexNumberInArray(point:Dynamic, findIn:Array<Point>):Int {
		for (pts in 0...findIn.length) {
			if (point.x == findIn[pts].x && point.y == findIn[pts].z)
				return pts;
		}
		throw "Not part of this array";
	}
}
