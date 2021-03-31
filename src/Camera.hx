import h3d.col.Bounds;
import h3d.Vector;

class Camera extends dn.Process {
	public var target(default, set) : Null<Entity>;

	function set_target(v : Null<Entity>) {
		if ( parallax != null && v != null ) {
			parallax.x = v.footX;
			parallax.z = v.footY;
		}
		return target = v;
	}

	public var s3dCam(get, never) : h3d.Camera;

	inline function get_s3dCam() return Boot.inst.s3d.camera;

	public var x : Float;
	public var y : Float;

	public var dx : Float;
	public var dy : Float;

	public static var ppu = 2;

	var yMult : Float;
	var parallax : Parallax;

	// public var wid(get, never):Int;
	// public var hei(get, never):Int;

	public function new() {
		super(Game.inst);
		x = y = 0;
		dx = dy = 0;
		updateCamera(M.round(x), M.round(y));
		// little hack to prevent z-fight
		var temp = new h3d.scene.CameraController(Boot.inst.s3d);
		temp.loadFromCamera();
		temp.remove();

		parallax = new Parallax(Boot.inst.s3d);
		parallax.y = -1;
		onResize();
	}

	function updateCamera(?x = 0., ?y = 0.) {
		if ( parallax != null ) {
			parallax.x = x;
			parallax.z = y;
		}
		s3dCam.target.x = (x);
		s3dCam.target.z = (y);
		s3dCam.pos = s3dCam.target.add(new Vector(0, -(w() * 1) / (2 * ppu * Math.tan(-s3dCam.getFovX() * 0.5 * (Math.PI / 180))), -0.001));
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if ( target != null ) {
			x = target.centerX;
			y = target.centerY;
		}
	}

	var shakePower = 1.0;

	public function shakeS(t : Float, ?pow = 1.0) {
		cd.setS("shaking", t, false);
		shakePower = pow;
	}

	public override function preUpdate() {
		cd.update(tmod);
	}

	override function update() {
		super.update();
		// updateCamera(M.round(x), M.round(y / yMult) * yMult);
	}

	override function postUpdate() {
		super.postUpdate();
		if ( !ui.Console.inst.hasFlag("scroll") ) {
			if ( target != null ) {
				yMult = (M.fabs(target.dx) > 0.001 && M.fabs(target.dy) > 0.001) ? .5 : 1;
				var s = 0.006;
				var deadZone = 5;
				var tx = target.footX;
				var ty = target.footY;
				var d = M.dist(x, y, tx, ty);
				if ( d >= deadZone ) {
					var a = Math.atan2(ty - y, tx - x);
					dx += Math.cos(a) * (d - deadZone) * s * tmod;
					dy += Math.sin(a) * (d - deadZone) * s * tmod;
				}

				var frict = 0.9;
				x += (dx * tmod);
				dx *= Math.pow(frict, tmod);

				y += dy * tmod;
				dy *= Math.pow(frict, tmod);
				updateCamera(M.round(x), M.round(y));
			}
			// Rounding

			// x = M.round(x);
			// y = M.round(y / yMult) * yMult;
		}
	}

	override function onDispose() {
		super.onDispose();
		if ( parallax != null ) {
			parallax.remove();
			parallax = null;
		}
	}

	override function onResize() {
		super.onResize();
		if ( parallax != null ) parallax.drawParallax();
	}
}
