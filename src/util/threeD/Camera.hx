package util.threeD;

import cherry.soup.EventSignal.EventSignal0;
import core.DispProp;
import dn.M;
import en.Entity;
import game.client.render.Parallax;
import h3d.scene.CameraController;

class Camera extends CameraController {

	public var targetEntity : DispProp<Null<Entity>> = new DispProp( null );

	public var s3dCam( get, never ) : h3d.Camera;

	inline function get_s3dCam() : h3d.Camera return Boot.inst.s3d.camera;

	public var dx : Float = 0;
	public var dy : Float = 0;

	public var onMove : EventSignal0;

	public var zNearK = 0.9;
	public var zFarK = 100.;

	var frict = 0.9;
	var yMult : Float;
	var parallax : Parallax;

	final isoDeg = 30;
	var xyDist = 300.;
	var a : Float;
	var b : Float;
	var shakePower = 0.0;

	var doRound = true;

	public function new() {
		lockZPlanes = true;
		super( Boot.inst.s3d );
		onMove = new EventSignal0();
		refreshDimensions();
		updateCamera();
		loadFromCamera();
		
		targetEntity.onValue.add( setTargetEntity );
		targetOffset.w = 0.5;
	}

	function setTargetEntity( v : Null<Entity> ) {
		if ( parallax != null && v != null ) {
			parallax.x = v.model.footX.val;
			parallax.z = v.model.footY.val;
		}
		refreshDimensions();
		updateCamera();
	}

	function refreshDimensions() {
		var xyDistSq = xyDist * xyDist;
		a = Math.sqrt( 2 * xyDistSq );
		b = a * Math.tan( M.toRad( isoDeg ) );
	}

	override function onAdd() {
		scene = getScene();
		if ( curOffset.w == 0 )
			curPos.x *= scene.camera.fovY;
		curOffset.w = scene.camera.fovY; // load
		targetPos.load( curPos );
		targetOffset.load( curOffset );
	}

	override function syncCamera() {
		var cam = getScene().camera;
		var distance = distance;
		cam.target.load( curOffset );
		cam.target.w = 1;
		cam.pos.set(
			distance * Math.cos( theta ) * Math.sin( phi ) + cam.target.x,
			distance * Math.sin( theta ) * Math.sin( phi ) + cam.target.y,
			distance * Math.cos( phi ) + cam.target.z
		);
		if ( !lockZPlanes ) {
			cam.zNear = distance * zNearK;
			cam.zFar = distance * zFarK;
		}
		cam.fovY = curOffset.w;
		if ( doRound ) {
			cam.target.x = M.round( cam.target.x );
			cam.target.y = M.round( cam.target.y );
			cam.target.z = M.round( cam.target.z );

			cam.pos.x = M.round( cam.pos.x );
			cam.pos.y = M.round( cam.pos.y );
			cam.pos.z = M.round( cam.pos.z );
		}
		cam.update();
	}

	function updateCamera() {
		if ( parallax != null ) {
			parallax.x = x;
			parallax.y = y;
		}

		s3dCam.target.x = Util.roundTo( targetOffset.x, 1 );
		s3dCam.target.y = Util.roundTo( targetOffset.y, 1 );

		s3dCam.pos.x = Util.roundTo( s3dCam.target.x + xyDist, 1 );
		s3dCam.pos.y = Util.roundTo( s3dCam.target.y + xyDist, 1 );
		s3dCam.pos.z = Util.roundTo( s3dCam.target.z + b, 1 );
		// s3dCam.fovY = 1;

		if ( parallax != null ) parallax.setPosition( s3dCam.pos.x, s3dCam.pos.y, s3dCam.pos.z );
		// s3dCam.pos = s3dCam.target.add( new Vector( 0, -( w() * 1 ) / ( 2 * ppu * Math.tan(-s3dCam.getFovX() * 0.5 * ( Math.PI / 180 ) ) ), -0.01 ) );
	}

	public inline function stopTracking() {
		targetEntity.val = null;
	}

	public function recenter() {
		if ( targetEntity.val != null ) {
			targetOffset.x = targetEntity.val.model.footX;
			targetOffset.y = targetEntity.val.model.footY;
			updateCamera();
			onMove.dispatch();
		}
	}
}
