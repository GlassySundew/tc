import h3d.Vector;

class Camera extends dn.Process {
	public var target:Null<Entity>;

	public var x(default, set):Float;
	public var y(default, set):Float;

	public var dx:Float;
	public var dy:Float;
	// public var wid(get, never):Int;
	// public var hei(get, never):Int;

	public function new() {
		super(Game.inst);
		x = y = 0;
		dx = dy = 0;
	}

	inline function set_x(v:Float) {
		Boot.inst.s3d.camera.target.x = v;
		Boot.inst.s3d.camera.pos = Boot.inst.s3d.camera.target.add(new Vector(0, Const.CAM_OFFSET,-30));

		return x = v;
	}

	inline function set_y(v:Float) {
		Boot.inst.s3d.camera.target.z = v;
		Boot.inst.s3d.camera.pos = Boot.inst.s3d.camera.target.add(new Vector(0, Const.CAM_OFFSET, -30));

		return y = v;
	}

	// function get_wid() {
	// 	return M.ceil(Game.inst.w() / Const.SCALE);
	// }

	// function get_hei() {
	// 	return M.ceil(Game.inst.h() / Const.SCALE);
	// }

	public function recenter() {
		if (target != null) {
			x = target.centerX;
			y = target.centerY;
		}
	}

	public inline function scrollerToGlobalX(v:Float)
		return v * Const.SCALE + Game.inst.scroller.x;

	public inline function scrollerToGlobalY(v:Float)
		return v * Const.SCALE + Game.inst.scroller.y;

	var shakePower = 1.0;

	public function shakeS(t:Float, ?pow = 1.0) {
		cd.setS("shaking", t, false);
		shakePower = pow;
	}

	public function preUpdate() {
		cd.update(tmod);
	}

	override function update() {
		if (target != null) {
			var s = 0.006;
			var deadZone = 5;
			var tx = target.footX;
			var ty = target.footY; //- target.cy * Const.GRID_HEIGHT;
			var d = M.dist(x, y, tx, ty);
			if (d >= deadZone) {
				var desired = new Vector(tx, ty);
				var smooth = new Vector();
				smooth.lerp(new Vector(x, y), desired, 0.03 * tmod);
				x = smooth.x;
				y = smooth.y;
				
			}
		}
		super.update();
	}

	override function postUpdate() {
		super.postUpdate();
		

		if (!ui.Console.inst.hasFlag("scroll")) {
			// var level = Game.inst.level;
			// var scroller = Game.inst.scroller;

			// // Update scroller
			// if (wid < level.wid * Const.GRID_WIDTH)
			// 	scroller.x = -x + wid * 0.5;
			// else
			// 	scroller.x = wid * 0.5 - level.wid * 0.5 * Const.GRID_WIDTH;
			// if (hei < level.hei * Const.GRID_HEIGHT)
			// 	scroller.y = -y + hei * 0.5;
			// else
			// 	scroller.y = hei * 0.5 - level.hei * 0.5 * Const.GRID_HEIGHT;

			// // Clamp
			// if (wid < level.wid * Const.GRID_WIDTH)
			// 	scroller.x = M.fclamp(scroller.x, wid - level.wid * Const.GRID_WIDTH, 0);
			// if (hei < level.hei * Const.GRID_HEIGHT)
			// 	scroller.y = M.fclamp(scroller.y, hei - level.hei * Const.GRID_HEIGHT, 0);

			// // Shakes
			// if (cd.has("shaking")) {
			// 	scroller.x += Math.cos(ftime * 1.16) * 1 * Const.SCALE * shakePower * cd.getRatio("shaking");
			// 	scroller.y += Math.sin(0.3 + ftime * 1.33) * 1 * Const.SCALE * shakePower * cd.getRatio("shaking");
			// }

			// Rounding
			if (!target.isMoving()) {
				// x = M.ceil(x);
				// y = M.ceil(y);
			}
		}
	}
}
