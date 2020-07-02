package en;

import ui.player.ButtonIcon;
import hxd.Key;
import hxd.Event;
import h2d.Object;
import hxGeomAlgo.PolyTools.Tri;
import hxGeomAlgo.HxPoint;
import h3d.prim.Polygon;
import hxd.IndexBuffer;
import h3d.col.Point;
import h2d.filter.Glow;
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

	var interactable(default, set):Bool = false;

	inline function set_interactable(v:Bool) {
		v ? 1 : {turnOffHighlight(); buttonIcon != null ? buttonIcon.dispose() : 1;};
		return interactable = v;
	}

	var highlightingColor:String;
	var polyPrim:Polygon;
	var buttonIcon:ButtonIcon;
	var filter:Glow;
	var idx:IndexBuffer;
	var translatedPoints:Array<Point> = [];
	var polygonized:Array<Tri>;
	var points:Array<HxPoint>;
	var iconParent:Object;

	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		super(x, z, tmxObj);

		var pixels = Pixels.fromBytes(tex.capturePixels().bytes, Std.int(spr.tile.width), Std.int(spr.tile.height));
		points = new MarchingSquares(pixels).march();
		polygonized = (EarCut.triangulate(points));

		for (i in polygonized)
			for (j in i)
				translatedPoints.push(new Point(j.x, 0, j.y));

		idx = new IndexBuffer();
		for (poly in 0...polygonized.length) {
			idx.push(findVertexNumberInArray(polygonized[poly][0], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][1], translatedPoints));
			idx.push(findVertexNumberInArray(polygonized[poly][2], translatedPoints));
		}

		polyPrim = new Polygon(translatedPoints, idx);
		interact = new h3d.scene.Interactive(polyPrim.getCollider(), mesh);
		interact.rotate(-0.01, hxd.Math.degToRad(180), hxd.Math.degToRad(90));

		var highlightColor = (try tmxTile.properties.get("highlight") catch (e:Dynamic) "ffffffff");
		if (highlightColor == null)
			highlightColor = "ffffffff";

		filter = new h2d.filter.Glow(Color.hexToInt(highlightingColor != null ? highlightingColor : highlightColor), 1.2, 4, 1, 1.5, true);
		interact.onOver = function(e:hxd.Event) {
			if (interactable) {
				bmp.filter = filter;
				filter.enable = true;
				cd.setS("keyboardIconInit", .4);
				cd.setS("interacted", Const.INFINITE);
			}
		};

		interact.onMove = interact.onCheck = function(e:hxd.Event) {};
		interact.onOut = function(e:hxd.Event) turnOffHighlight();
		interact.onTextInput = function(e:Event) {
			// trace(Key.isPressed(Key.E));
		}
	}

	public function rebuildInteract() {
		polyPrim.translate(-spr.tile.width * spr.pivot.centerFactorX, 0, -spr.tile.height * spr.pivot.centerFactorY);
		interact.shape = polyPrim.getCollider();
	}

	override function postUpdate() {
		super.postUpdate();
		// if (tw != null) {
		// }
		if (interactable)
			updateKeyIcon();
		// deactivate interactive if inventory is opened
		interact.visible = !player.inventory.base.visible;
	}

	public function turnOffHighlight() {
		cd.unset("interacted");

		filter.enable = false;
		if (buttonIcon != null)
			buttonIcon.dispose();
	}

	function updateKeyIcon() {
		if (!cd.has("keyboardIconInit") && cd.has("interacted")) {
			var pos = Boot.inst.s3d.camera.project(mesh.x, 0, mesh.z, getS2dScaledWid(), getS2dScaledHei());
			cd.unset("interacted");
			buttonIcon = new ButtonIcon(pos.x, pos.y);
			tw.createS(buttonIcon.container.icon.alpha, 0 > 1, TEaseIn, .4);
		}
		if (buttonIcon != null) {
			var pos = Boot.inst.s3d.camera.project(mesh.x, 0, mesh.z, getS2dScaledWid(), getS2dScaledHei());

			buttonIcon.centerFlow.x = pos.x - 1;
			buttonIcon.centerFlow.y = pos.y - 100 / Const.SCALE;
			
			buttonIcon.container.icon.tile = buttonIcon.buttonSpr.tile;
			// buttonIcon.container.icon.scaleX = buttonIcon.container.icon.scaleY = 2;
		}
	}

	function findVertexNumberInArray(point:Dynamic, findIn:Array<Point>):Int {
		for (pts in 0...findIn.length) {
			if (point.x == findIn[pts].x && point.y == findIn[pts].z)
				return pts;
		}
		throw "Not part of this array";
	}
}
