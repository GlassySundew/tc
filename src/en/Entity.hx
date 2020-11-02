package en;

import h2d.Scene;
import differ.shapes.Circle;
import differ.Collision;
import ch3.scene.TileSprite;
import en.objs.IsoTileSpr;
import h3d.Matrix;
import hxd.Key;
import format.tmx.Data.TmxTilesetTile;
import format.tmx.Tools;
import format.tmx.Data.TmxTile;
import h2d.Tile;
import h2d.Bitmap;
import format.tmx.Data.TmxObject;
import h3d.prim.Sphere;
import differ.shapes.Shape;
import en.player.Player;
import h3d.prim.Cylinder;
import tools.CPoint;
import dn.heaps.slib.HSprite;
import h3d.mat.Texture;
import h3d.prim.Cube;
import h3d.Vector;
import h3d.scene.Mesh;

@:keep class Entity {
	// private var anim:String;
	public static var ALL: Array<Entity> = [];
	public static var GC: Array<Entity> = [];
	/**
		Map of multiple shapes, 1st vector is a center of polygon Shape, 2nd polygon is a position of a poly
	**/
	public var collisions = new Map<Shape, {cent: Vector, offset: Vector}>();

	public var game(get, never): Game;

	inline function get_game() return Game.inst;

	var level(get, never): Level;

	inline function get_level() return Game.inst.level;

	public var destroyed(default, null) = false;
	public var tmod(get, never): Float;

	public var uid: Int;
	public var cx: Float = 0;
	public var cy: Float = 0;
	public var xr = 0.5;
	public var yr = 0.5;
	public var zr = 0.;

	public var dx = 0.;
	public var dy = 0.;
	public var dz = 0.;
	public var bdx = 0.;
	public var bdy = 0.;

	public var dxTotal(get, never): Float;

	inline function get_dxTotal() return dx + bdx;

	public var dyTotal(get, never): Float;

	inline function get_dyTotal() return dy + bdy;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var bumpReduction = 0.;

	public var centerX(get, never): Float;

	inline function get_centerX() return footX;

	public var centerY(get, never): Float;

	inline function get_centerY() return footY - 11;

	public var dir(default, set) = 6;

	inline function get_tmod() return Game.inst.tmod;

	public var player(get, never): en.player.Player;

	inline function get_player() return Game.inst.player;

	public var footX(get, set): Float;

	inline function get_footX() return (cx + xr);

	inline function set_footX(v: Float) { // небольшой костыль
		xr = ((v)) % 1;
		cx = (Math.floor((v)));
		return v;
	}

	public var footY(get, set): Float;

	inline function get_footY() return (cy + yr - zr);

	inline function set_footY(v: Float) { // аналогично
		yr = ((v)) % 1;
		cy = (Math.floor((v)));
		return v;
	}

	public var tmxTile(get, never): TmxTilesetTile;

	inline function get_tmxTile() return Tools.getTileByGid(Level.inst.data, tmxObj.objectType.getParameters()[0]);

	public var tmxObj: TmxObject;
	public var colorAdd: h3d.Vector;
	public var spr: HSprite;
	public var mesh: IsoTileSpr;

	public var tmpDt: Float;
	public var tmpCur: Float;

	public var lastFootX: Float;
	public var lastFootY: Float;

	public var curFrame: Float = 0;
	public var prim: Cube;

	private var rotAngle: Float = -0.01;
	private var tex: Texture;
	var bmp: Bitmap;

	public var cd: dn.Cooldown;
	public var tw: Tweenie;

	public static var isoCoefficient = 1.2;

	var debugLabel: Null<h2d.Text>;

	public function new(?x: Float = 0, ?z: Float = 0, ?tmxObj: Null<TmxObject>) {
		uid = Const.NEXT_UNIQ;
		ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);
		tw = new Tweenie(Const.FPS);

		if (spr == null) throw "spr hasnt been initialised";

		this.tmxObj = tmxObj;
		spr.colorAdd = colorAdd = new h3d.Vector();
		tex = new Texture(Std.int(spr.tile.width), Std.int(spr.tile.height), [Target]);
		spr.tile.getTexture().filter = Nearest;
		spr.drawTo(tex);
		mesh = new IsoTileSpr(spr.tile, false, Boot.inst.s3d);
		mesh.material.mainPass.setBlendMode(AlphaAdd);

		mesh.rotate(0, -rotAngle, M.toRad(90));
		var s = mesh.material.mainPass.addShader(new h3d.shader.ColorAdd());
		s.color = colorAdd;
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.depth(false, Less);

		if (tmxObj != null && tmxObj.flippedVertically) spr.scaleX = -1;
		// TODO semi-transparent overlapping
		// var s = new h3d.mat.Stencil();
		// s.setFunc(LessEqual, 0);
		// s.setOp(Keep, DecrementWrap, Keep);
		// mesh.material.mainPass.stencil = s;
		setFeetPos(x, z);
	}

	public function isOfType<T: Entity>(c: Class<T>) return Std.isOfType(this, c);

	public function as<T: Entity>(c: Class<T>): T return Std.downcast(this, c);

	public inline function angTo(e: Entity) return Math.atan2(e.footY - footY, e.footX - footX);

	public inline function angToPxFree(x: Float, y: Float) return Math.atan2(y - footY, x - footX);

	public function blink(?c = 0xffffff) {
		colorAdd.setColor(c);
		cd.setS("colorMaintain", 0.03);
	}

	public inline function isMoving() return M.fabs(dxTotal) >= 0.01 || M.fabs(dyTotal) >= 0.01;

	public inline function at(x, y) return cx == x && cy == y;

	public inline function isAlive() {
		return !destroyed; // && life > 0;
	}

	public function isLocked() return cd.has("lock");

	public function lock(?ms: Float) cd.setMs("lock", ms != null ? ms : 1 / 0);

	public function unlock() cd.unset("lock");

	inline function dropItem(item: en.Item, ?angle: Float, ?power: Float = 0): en.Item {
		var fItem = new FloatingItem(footX, footY, item);
		fItem.bump(Math.cos(angle) * power, Math.sin(angle) * power, 0);
		fItem.lock(1000);
		item.remove();
		item = null;
		return item;
	}

	inline function set_dir(v) {
		if (dir != v) {
			// spr.anim.getCurrentAnim().curFrameCpt = curFrame;
		}

		return dir = v == 0 ? 0 : v == 1 ? 1 : v == 2 ? 2 : v == 3 ? 3 : v == 4 ? 4 : v == 5 ? 5 : v == 6 ? 6 : v == 7 ? 7 : dir;
	}

	public inline function bumpAwayFrom(e: Entity, spd: Float, ?spdZ = 0., ?ignoreReduction = false) {
		var a = e.angTo(this);
		bump(Math.cos(a) * spd, Math.sin(a) * spd, spdZ, ignoreReduction);
	}

	public function bump(x: Float, y: Float, z: Float, ?ignoreReduction = false) {
		var f = ignoreReduction ? 1.0 : 1 - bumpReduction;
		bdx += x * f;
		bdy += y * f;
		dz += z * f;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public inline function distCase(e: Entity) {
		return M.dist(cx + xr, cy + yr, e.cx + e.xr, e.cy + e.yr);
	}

	public inline function distPx(e: Entity) {
		return M.dist(footX, footY, e.footX, e.footY);
	}

	public inline function distCaseFree(tcx: Int, tcy: Int, ?txr = 0.5, ?tyr = 0.5) {
		return M.dist(cx + xr, cy + yr, tcx + txr, tcy + tyr);
	}

	public inline function distPxFree(x: Float, y: Float) {
		return M.dist(footX, footY, x, y);
	}

	public function makePoint() return new CPoint(cx, cy, xr, yr);

	public inline function destroy() {
		if (!destroyed) {
			destroyed = true;
			GC.push(this);
		}
	}

	public function dispose() {
		ALL.remove(this);
		spr.remove();

		if (debugLabel != null) {
			debugLabel.remove();
			debugLabel = null;
		}
		if (mesh != null) {
			mesh.tile.dispose();
			mesh.primitive.dispose();
			mesh.remove();
		}
		cd.destroy();
		tex.dispose();
		tw.destroy();
		cd = null;
		for (i in collisions.keys()) i.destroy();

		collisions = null;
		spr = null;
		mesh = null;
	}

	public function setFeetPos(x, y) {
		footX = x;
		footY = y;
	}

	public function setPosCase(x, y, ?xr = 0.5, ?yr = 0.5) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
		lastFootX = footX;
		lastFootY = footY;
	}

	public function kill(by: Null<Entity>) {
		destroy();
	}

	function checkCollisions() {
		for (collObj in collisions.keys()) {
			collObj.x = footX
				- collisions.get(collObj).cent.x
				- (spr.pivot.centerFactorX * spr.tile.width - collisions.get(collObj).offset.x - collisions.get(collObj).cent.x);
			collObj.y = footY
				- collisions.get(collObj).cent.y
				+ (spr.pivot.centerFactorY * spr.tile.height + collisions.get(collObj).offset.y + collisions.get(collObj).cent.y);
		}
	}

	public function checkCollsAgainstAll() {
		for (ent in Entity.ALL) {
			if (!(ent.isOfType(FloatingItem) || isOfType(FloatingItem)) && ent != this) {
				for (collObj in collisions.keys()) {
					for (entCollObj in ent.collisions.keys()) {
						var collideInfo = Collision.shapeWithShape(collObj, entCollObj);
						if (collideInfo != null) {
							collObj.x += (collideInfo.separationX);
							collObj.y += (collideInfo.separationY);

							footX += (collideInfo.separationX);
							footY += (collideInfo.separationY);
						}
					}
				}
			}
		}
		for (poly in Level.inst.walkable) {
			for (collObj in collisions.keys()) {
				var collideInfo = Collision.shapeWithShape(collObj, poly);
				if (collideInfo != null) {
					collObj.x += (collideInfo.separationX);
					collObj.y += (collideInfo.separationY);

					footX += (collideInfo.separationX);
					footY += (collideInfo.separationY);
				}
			}
		}
		// footX = (collisions[0].x);
		// footY = (collisions[0].y);
	}

	public function preUpdate() {
		spr.anim.update(tmod);
		cd.update(tmod);
		tw.update(tmod);
	}

	public function update() {
		@:privateAccess if (spr.anim.getCurrentAnim() != null) {
			if (tmpCur != 0 && (spr.anim.getCurrentAnim().curFrameCpt - (tmpDt)) == 0) // ANIM LINK HACK
				spr.anim.getCurrentAnim().curFrameCpt = tmpCur + spr.anim.getAnimCursor();
			tmpDt = tmod * spr.anim.getCurrentAnim().speed;
			tmpCur = spr.anim.getCurrentAnim().curFrameCpt;
		}
		// x
		var steps = M.ceil(M.fabs(dxTotal * tmod));
		var step = dxTotal * tmod / steps;

		step = (M.fabs(dy) > 0.0001) ? step * isoCoefficient : step; // ISO FIX

		while (steps > 0) {
			xr += step;
			while (xr > 1) {
				xr--;
				cx++;
			}
			while (xr < 0) {
				xr++;
				cx--;
			}
			steps--;
		}

		dx *= Math.pow(frict, tmod);
		bdx *= Math.pow(bumpFrict, tmod);
		if (M.fabs(dx) <= 0.0005 * tmod) dx = 0;
		if (M.fabs(bdx) <= 0.0005 * tmod) bdx = 0;

		// y
		var steps = M.ceil(M.fabs(dyTotal * tmod));
		// var step = 0.;

		step = (M.fabs(step) > 0.001) ? (dyTotal * tmod / steps * isoCoefficient * 0.5) : (dyTotal * tmod / steps); // ISO FIX

		while (steps > 0) {
			yr += step;
			while (yr > 1) {
				yr--;
				cy++;
			}
			while (yr < 0) {
				yr++;
				cy--;
			}
			steps--;
		}

		dy *= Math.pow(frict, tmod);
		bdy *= Math.pow(bumpFrict, tmod);
		if (M.fabs(dy) <= 0.0005 * tmod) dy = 0;
		if (M.fabs(bdy) <= 0.0005 * tmod) bdy = 0;
	}

	public function postUpdate() {
		if (mesh != null) {
			mesh.x = footX;
			mesh.z = footY;
			checkCollisions();

			// spr.scaleX = dir * sprScaleX;
			// spr.scaleY = sprScaleY;
			if (!cd.has("colorMaintain")) {
				colorAdd.r *= Math.pow(0.6, tmod);
				colorAdd.g *= Math.pow(0.6, tmod);
				colorAdd.b *= Math.pow(0.6, tmod);
			}

			// if (debugLabel != null) {
			// 	debugLabel.x = Std.int(footX - debugLabel.textWidth * 0.5);
			// 	debugLabel.y = Std.int(footY + 1);
			// }
			// curFrame = spr.anim.getCurrentAnim().curFrameCpt;

			if (!isMoving()) {
				footX = M.round(M.fabs(footX));
				footY = M.round(M.fabs(footY));
			}
		}
	}

	public function frameEnd() {
		if (mesh != null) {
			tex.clear(0, 0);
			spr.x = spr.scaleX > 0 ? -spr.tile.dx : spr.tile.dx + spr.tile.width;
			spr.y = -spr.tile.dy;
			spr.drawTo(tex);
			var tile = Tile.fromTexture(tex);
			tile.getTexture().filter = Nearest;
			tile.setCenterRatio(spr.pivot.centerFactorX, spr.pivot.centerFactorY);
			mesh.tile = tile;
		}
	}
}
