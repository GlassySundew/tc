package en;

import ui.InventoryGrid;
import haxe.io.Error;
import ui.EventInteractive;
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
	public var interact:EventInteractive;
	public var interactable(default, set):Bool = false;

	inline function set_interactable(v:Bool) {
		if (!v) {
			turnOffHighlight();
			if (buttonIcon != null)
				buttonIcon.dispose();
			interact.cursor = Default;
		}
		return interactable = v;
	}

	public var cdbI:Structures = null;
	public var useRange:Float = Const.DEF_USE_RANGE;

	var highlightingColor:String;
	var polyPrim:Polygon;
	var buttonIcon:ButtonIcon;
	var filter:Glow;
	var idx:IndexBuffer;
	var translatedPoints:Array<Point> = [];
	var polygonized:Array<Tri>;
	var points:Array<HxPoint>;
	var iconParent:Object;

	var inv = new CellGrid2D(4, 4);

	function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
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
		interact = new EventInteractive(polyPrim.getCollider(), mesh);
		interact.rotate(-0.01, hxd.Math.degToRad(180), hxd.Math.degToRad(90));

		if (tmxObj != null && tmxObj.flippedVertically)
			interact.scaleX = -1;

		// var highlightColor = (try tmxTile.properties.get("highlight") catch (e:Dynamic) "ffffffff");
		var highlightColor = null;
		if (highlightColor == null)
			highlightColor = "ffffffff";

		filter = new h2d.filter.Glow(Color.hexToInt(highlightingColor != null ? highlightingColor : highlightColor), 1.2, 4, 1, 1.5, true);

		function activateInteractive() {
			if (interactable && isInPlayerRange()) {
				turnOnHighlight();
				return true;
			} else
				return false;
		}
		// Нажатие для того, чтобы сломать структуру
		interact.onPushEvent.add(event -> {});
		interact.onOverEvent.add((_) -> activateInteractive());
		interact.onOutEvent.add((e:hxd.Event) -> {
			turnOffHighlight();
		});

		// CDB parsed entry corresponding to this structure instance
		eregClass.match('$this'.toLowerCase());
		try {
			cdbI = Data.structures.resolve(eregClass.matched(1));
		} catch (Dynamic) {
			try {
				cdbI = Data.structures.resolve(spr.groupName);
			} catch (Dynamic) {}
		}
		// Setting interaciton range from cdb

		if (cdbI != null) {
			useRange = cdbI.use_range;

			if (cdbI.isoHeight != 0 && cdbI.isoWidth != 0) {
				mesh.isLong = true;
				mesh.isoWidth = cdbI.isoWidth;
				mesh.isoHeight = cdbI.isoHeight;
				mesh.renewDebugPts();
			}
		}
	}

	inline function isInPlayerRange()
		return distPx(player) <= useRange;

	public function rebuildInteract() {
		var facX = (tmxObj != null && tmxObj.flippedVertically) ? 1 - spr.pivot.centerFactorX : spr.pivot.centerFactorX;
		polyPrim.translate(-spr.tile.width * facX, 0, -spr.tile.height * spr.pivot.centerFactorY);
		interact.shape = polyPrim.getCollider();
	}

	public function turnOnHighlight() {
		bmp.filter = filter;
		filter.enable = true;
		cd.setS("keyboardIconInit", .4);
		cd.setS("interacted", Const.INFINITE);
	}

	public function turnOffHighlight() {
		cd.unset("interacted");
		bmp.filter = null;
		filter.enable = false;
		if (buttonIcon != null)
			buttonIcon.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
		// if (tw != null) {
		// }
		if (interactable)
			updateKeyIcon();
		// deactivate interactive if inventory is opened
		interact.visible = !player.ui.inventory.sprInv.visible && isInPlayerRange();
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
		}
	}

	function findVertexNumberInArray(point:Dynamic, findIn:Array<Point>):Int {
		for (pts in 0...findIn.length) {
			if (point.x == findIn[pts].x && point.y == findIn[pts].z)
				return pts;
		}
		throw "Not part of this array";
	}

	function dropAllItems(?angle:Float, ?power:Float) {
		for (i in inv.grid) {
			for (j in i) {
				if (j.item != null) {
					j.item = dropItem(j.item, Math.random() * M.toRad(360), Math.random() * .03 * 48 + .01);
				}
			}
		}
	}

	override function dispose() {
		interact.visible = false;
		interact.cursor = Default;
		super.dispose();

		interact.remove();
		buttonIcon.remove();
		filter = null;
		polyPrim.dispose();
	}
}
