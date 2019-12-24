package en;

import h3d.prim.Sphere;
import differ.shapes.Shape;
import en.player.Player;
import h3d.scene.TileSprite;
import h3d.prim.Cylinder;
import tools.CPoint;
import dn.heaps.slib.HSprite;
import h3d.mat.Texture;
import h3d.prim.Cube;
import h3d.Vector;
import h3d.scene.Mesh;

class Entity {
	// private var anim:String;
	public static var ALL:Array<Entity> = [];
	public static var GC:Array<Entity> = [];

	public var collisions:Array<Shape> = [];

	public var game(get, never):Game;

	inline function get_game()
		return Game.inst;

	var level(get, never):Level;

	inline function get_level()
		return Game.inst.level;

	public var hei:Int = 32;
	public var wid:Int = 32;

	public var destroyed(default, null) = false;
	public var tmod(get, never):Float;

	public var uid:Int;
	public var cx:Float = 0;
	public var cy:Float = 0;
	public var xr = 0.5;
	public var yr = 0.5;
	public var zr = 0.;

	public var dx = 0.;
	public var dy = 0.;
	public var dz = 0.;
	public var bdx = 0.;
	public var bdy = 0.;

	public var dxTotal(get, never):Float;

	inline function get_dxTotal()
		return dx + bdx;

	public var dyTotal(get, never):Float;

	inline function get_dyTotal()
		return dy + bdy;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;

	public var centerX(get, never):Float;

	inline function get_centerX()
		return footX;

	public var centerY(get, never):Float;

	inline function get_centerY()
		return footY - hei * 0.5;

	public var dir(default, set) = 6;

	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;

	public var sprOffX = 0.;
	public var sprOffY = 0.;

	public var sprOffCollX = 0.;
	public var sprOffCollY = 0.;

	public var bottomAlpha = 0;

	inline function get_tmod()
		return Game.inst.tmod;

	public var player(get, never):en.player.Player;

	inline function get_player()
		return Game.inst.player;

	public var tex:Texture;

	public var footX(get, set):Float;

	inline function get_footX()
		return (cx + xr + sprOffX) * Const.GRID_WIDTH;

	inline function set_footX(v:Float) { // небольшой костыль
		xr = (v / Const.GRID_WIDTH) % 1;
		cx = Math.floor(v / Const.GRID_WIDTH) - sprOffX;
		return v;
	}

	public var footY(get, set):Float;

	inline function get_footY()
		return (cy + yr - zr + sprOffY) * Const.GRID_WIDTH;

	inline function set_footY(v:Float) { // аналогично
		yr = (v / Const.GRID_WIDTH) % 1;
		cy = Math.floor(v / Const.GRID_WIDTH) - sprOffY;
		return v;
	}

	public var colorAdd:h3d.Vector;
	public var spr:HSprite;
	public var mesh:TileSprite;

	public var tmpDt:Float;
	public var tmpCur:Float;

	public var lastFootX:Float;
	public var lastFootY:Float;

	public var curFrame:Float = 0;
	public var prim:Cube;

	private var rotAngle:Float = -.00001;
	private var pos:Vector;

	public var cd:dn.Cooldown;

	public static var isoCoefficient = 1.2;

	var debugLabel:Null<h2d.Text>;


	public function new(?x:Float = 0, ?z:Float = 0) {
		uid = Const.NEXT_UNIQ;
		ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);

		if (spr == null)
			spr = new HSprite(Assets.tiles);


		game.scroller.add(spr, 10);
		// spr.setCenterRatio(0.5, 1);
		spr.colorAdd = colorAdd = new h3d.Vector();
		spr.visible = false;
		spr.tile.getTexture().filter = Nearest;

		mesh = new TileSprite(spr.tile, false, Boot.inst.s3d, true, Y);
		mesh.material.mainPass.setBlendMode(Alpha);
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.depth(false, LessEqual);
		mesh.rotate(rotAngle, 0, 0);
		// mesh.scaleZ = (spr.tile.height / Math.cos(rotAngle)) / spr.tile.height;

		var s = mesh.material.mainPass.addShader(new h3d.shader.ColorAdd());
		s.color = colorAdd;
		setPosCase(x, z);
	}

	function blah() {
		trace("blah");
	}

	public function is<T:Entity>(c:Class<T>)
		return Std.is(this, c);

	public function blink(?c = 0xffffff) {
		colorAdd.setColor(c);
		cd.setS("colorMaintain", 0.03);
	}

	public inline function isMoving()
		return M.fabs(dxTotal) >= 0.01 || M.fabs(dyTotal) >= 0.01;

	public inline function at(x, y)
		return cx == x && cy == y;

	public inline function isAlive() {
		return !destroyed; // && life > 0;
	}

	public function isLocked()
		return cd.has("lock");

	inline function set_dir(v) {
		if (dir != v) {
			// spr.anim.getCurrentAnim().curFrameCpt = curFrame;
		}

		return dir = v == 0 ? 0 : v == 1 ? 1 : v == 2 ? 2 : v == 3 ? 3 : v == 4 ? 4 : v == 5 ? 5 : v == 6 ? 6 : v == 7 ? 7 : dir;
	}

	public function makePoint()
		return new CPoint(cx, cy, xr, yr);

	public inline function destroy() {
		if (!destroyed) {
			destroyed = true;
			GC.push(this);
		}
	}

	public function dispose() {
		ALL.remove(this);

		spr.remove();
		spr = null;

		if (debugLabel != null) {
			debugLabel.remove();
			debugLabel = null;
		}

		cd.destroy();
		cd = null;
	}

	public function setPosCase(x, y, ?xr = 0.5, ?yr = 0.5) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
		lastFootX = footX;
		lastFootY = footY;

		pos = new Vector(x, 0, y);
	}

	public function kill(by:Null<Entity>) {
		destroy();
	}

	function checkCollisions() {
		collisions[0].x = mesh.x + sprOffCollX * Const.GRID_WIDTH;
		collisions[0].y = mesh.z + sprOffCollY * Const.GRID_WIDTH;
	}

	public function preUpdate() {
		cd.update(tmod);
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
		if (M.fabs(dx) <= 0.0005 * tmod)
			dx = 0;
		if (M.fabs(bdx) <= 0.0005 * tmod)
			bdx = 0;

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
		if (M.fabs(dy) <= 0.0005 * tmod)
			dy = 0;
		if (M.fabs(bdy) <= 0.0005 * tmod)
			bdy = 0;
		

	}

	public function postUpdate() {
		mesh.x = spr.x = footX;
		mesh.z = spr.y = footY;
		mesh.y = ((spr.tile.height - bottomAlpha) / 2) * mesh.scaleZ * Math.sin(-rotAngle);

		// spr.scaleX = dir * sprScaleX;
		// spr.scaleY = sprScaleY;
		if (!cd.has("colorMaintain")) {
			colorAdd.r *= Math.pow(0.6, tmod);
			colorAdd.g *= Math.pow(0.6, tmod);
			colorAdd.b *= Math.pow(0.6, tmod);
		}

		if (debugLabel != null) {
			debugLabel.x = Std.int(footX - debugLabel.textWidth * 0.5);
			debugLabel.y = Std.int(footY + 1);
		}
		// curFrame = spr.anim.getCurrentAnim().curFrameCpt;
		checkCollisions();

		if (!isMoving()) {
			footX = M.round(M.fabs(footX));
			footY = M.round(M.fabs(footY));
		}
	}

	public function frameEnd() {
		mesh.tile = spr.tile;
		lastFootX = footX;
		lastFootY = footY;
	}
}
