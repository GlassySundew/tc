package util.threeD;

import h3d.col.Point;
import dn.M;
import dn.Process;

@:access( h3d.scene.CameraController )
class CameraProcess extends Process {

	public final camera : Camera;

	public function new( parent : Process ) {
		super( parent );
		camera = new Camera();

		camera.targetEntity.onValue.add( ( e ) -> delayer.addF( camera.onMove.dispatch, 3 ) );
	}

	public override function preUpdate() {
		cd.update( tmod );

		if ( camera.targetEntity.val != null ) {
			var s = 0.006;
			var deadZone = 5;
			var tx = camera.targetEntity.val.model.footX.val;
			var ty = camera.targetEntity.val.model.footY.val;
			var d = M.dist( camera.targetOffset.x, camera.targetOffset.y, tx, ty );
			if ( d >= deadZone ) {
				var a = Math.atan2( ty - camera.targetOffset.y, tx - camera.targetOffset.x );
				camera.dx += Math.cos( a ) * ( d - deadZone ) * s * tmod;
				camera.dy += Math.sin( a ) * ( d - deadZone ) * s * tmod;
			}

			camera.targetOffset.x += ( camera.dx * tmod );
			camera.dx *= Math.pow( camera.frict, tmod );

			camera.targetOffset.y += camera.dy * tmod;
			camera.dy *= Math.pow( camera.frict, tmod );

			if ( M.fabs( camera.dx ) <= ( 0.0005 * tmod ) ) camera.dx = 0;
			if ( M.fabs( camera.dy ) <= ( 0.0005 * tmod ) ) camera.dy = 0;

			if ( camera.dy != 0 || camera.dx != 0 ) camera.onMove.dispatch();
		}
	}

	public inline function refreshOrtho() : Void {
		if ( camera.s3dCam.orthoBounds != null ) {
			var halfW = Std.int( w() / Const.SCALE / 2 );
			var halfH = Std.int( h() / Const.SCALE / 2 );

			camera.s3dCam.orthoBounds.setMin( new Point(-halfW, -halfH, camera.s3dCam.zNear ) );
			camera.s3dCam.orthoBounds.setMax( new Point( halfW, halfH, camera.s3dCam.zFar ) );
			trace( camera.s3dCam.orthoBounds );
		}
	}

	override function onResize() {
		super.onResize();
		if ( camera.parallax != null ) {
			camera.parallax.drawParallax();
		}
		camera.onMove.dispatch();
	}

	public function shakeS( t : Float, ?pow = 1.0 ) {
		cd.setS( "shaking", t, false );
		camera.shakePower = pow;
	}

	override function onDispose() {
		super.onDispose();
		if ( camera.parallax != null ) {
			camera.parallax.remove();
			camera.parallax = null;
		}
	}
}
