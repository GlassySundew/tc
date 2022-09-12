package utils.s3d;

import h3d.col.Point;
import h3d.col.Bounds;
import dn.Process;
import en.Entity;
import game.client.GameClient;
import game.client.render.Parallax;
import h3d.Vector;

class Camera extends dn.Process {

	public var target( default, set ) : Null<Entity>;

	function set_target( v : Null<Entity> ) {
		if ( parallax != null && v != null ) {
			parallax.x = v.footX.val;
			parallax.z = v.footY.val;
		}
		return target = v;
	}

	public var s3dCam( get, never ) : h3d.Camera;

	inline function get_s3dCam() return Boot.inst.s3d.camera;

	public var x : Float;
	public var y : Float;

	public var dx : Float;
	public var dy : Float;

	public static var ppu = 3;

	var yMult : Float;
	var parallax : Parallax;

	final isoDeg = 30;
	var xyDist = 300.;
	var a : Float;
	var b : Float;

	public function new( ?parent : Process ) {
		super( parent == null ? GameClient.inst : parent );
		x = y = 0;
		dx = dy = 0;

		refreshDimensions();
		updateCamera( M.round( x ), M.round( y ) );

		parallax = new Parallax( Boot.inst.s3d );

		s3dCam.orthoBounds = new Bounds();
		onResize();
	}

	function refreshDimensions() {
		var xyDistSq = xyDist * xyDist;
		a = Math.sqrt( 2 * xyDistSq );
		b = a * Math.tan( M.toRad( isoDeg ) );
	}

	function updateCamera( ?x = 0., ?y = 0. ) {
		if ( parallax != null ) {
			parallax.x = x;
			parallax.y = y;
		}
		s3dCam.target.x = ( x );
		s3dCam.target.y = ( y );

		s3dCam.pos = s3dCam.target.add( new Vector( xyDist, xyDist, b ) ); // 282.842666667

		if ( parallax != null ) parallax.setPosition( s3dCam.pos.x, s3dCam.pos.y, s3dCam.pos.z );

		// s3dCam.pos = s3dCam.target.add( new Vector( 0, -( w() * 1 ) / ( 2 * ppu * Math.tan(-s3dCam.getFovX() * 0.5 * ( Math.PI / 180 ) ) ), -0.01 ) );
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if ( target != null ) {
			x = target.footX.val;
			y = target.footY.val;
		}
	}

	var shakePower = 1.0;

	public function shakeS( t : Float, ?pow = 1.0 ) {
		cd.setS( "shaking", t, false );
		shakePower = pow;
	}

	public inline function refreshOrtho() {
		if ( s3dCam.orthoBounds != null ) {
			s3dCam.orthoBounds.setMin( new Point(-w() / ppu / 2, -h() / ppu / 2, 0.02 ) );
			s3dCam.orthoBounds.setMax( new Point( w() / ppu / 2, h() / ppu / 2, 4000 ) );
		}
	}

	public override function preUpdate() {
		cd.update( tmod );
	}

	override function update() {
		super.update();
		// updateCamera(M.round(x), M.round(y / yMult) * yMult);
	}

	override function postUpdate() {
		super.postUpdate();
		if ( target != null ) {
			yMult = ( M.fabs( target.dx ) > 0.001 && M.fabs( target.dy ) > 0.001 ) ? .5 : 1;
			var s = 0.006;
			var deadZone = 5;
			var tx = target.footX.val;
			var ty = target.footY.val;
			var d = M.dist( x, y, tx, ty );
			if ( d >= deadZone ) {
				var a = Math.atan2( ty - y, tx - x );
				dx += Math.cos( a ) * ( d - deadZone ) * s * tmod;
				dy += Math.sin( a ) * ( d - deadZone ) * s * tmod;
			}

			var frict = 0.9;
			x += ( dx * tmod );
			dx *= Math.pow( frict, tmod );

			y += dy * tmod;
			dy *= Math.pow( frict, tmod );
			updateCamera( M.round( x ), M.round( y ) );
		}
		// Rounding

		// x = M.round(x);
		// y = M.round(y / yMult) * yMult;
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
		if ( parallax != null ) {
			// parallax.drawParallax();
		}
		refreshOrtho();
	}
}
