package util.threeD;

import game.client.GameClient;
import h3d.Vector;
import cherry.soup.EventSignal.EventSignal0;
import core.VO;
import dn.M;
import en.Entity;
import game.client.render.Parallax;
import h3d.scene.CameraController;

class Camera extends CameraController {

	public var targetEntity : VO<Null<Entity>> = new VO( null );

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
	var xyDist = 0.;
	var b : Float;
	var shakePower = 0.0;

	var doRound = true;
	var proc : CameraProcess;

	public function new( proc : CameraProcess ) {
		lockZPlanes = true;
		super( Boot.inst.s3d );
		onMove = new EventSignal0();
		refreshDimensions();
		updateCamera();
		loadFromCamera();

		this.proc = proc;

		targetEntity.addOnVal( setTargetEntity );
		targetOffset.w = 0.5;
	}

	function setTargetEntity( v : Null<Entity> ) {
		if ( parallax != null && v != null ) {
			parallax.x = v.model.footX.val;
			parallax.z = v.model.footY.val;
		}

		updateCamera();
		proc.delayer.addF( refreshDimensions, 1 );
	}

	function refreshDimensions() {
		var finalDist = -( GameClient.inst.w() * 1 ) / ( 2 * 3 * Math.tan(-s3dCam.getFovX() * 0.5 * ( Math.PI / 180 ) ) );

		b = finalDist * Math.sin( M.toRad( isoDeg ) );
		var a = finalDist * Math.cos( M.toRad( isoDeg ) );

		xyDist = a * Math.cos( M.toRad( 45 ) );
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

		if ( !lockZPlanes ) {
			cam.zNear = distance * zNearK;
			cam.zFar = distance * zFarK;
		}
		updateCamera();

		cam.fovY = curOffset.w;

		// cam.update();
	}

	function updateCamera() {
		if ( parallax != null ) {
			parallax.x = x;
			parallax.y = y;
		}
		refreshDimensions();

		s3dCam.target.x = targetOffset.x;
		s3dCam.target.y = targetOffset.y;

		if ( doRound ) {
			s3dCam.target.x = M.floor( s3dCam.target.x );
			s3dCam.target.y = M.floor( s3dCam.target.y );
			s3dCam.target.z = M.floor( s3dCam.target.z );
		}

		s3dCam.pos.x = s3dCam.target.x + xyDist;
		s3dCam.pos.y = s3dCam.target.y + xyDist;
		s3dCam.pos.z = s3dCam.target.z + b;
		// s3dCam.fovY = 1;

		if ( parallax != null )
			parallax.setPosition(
				s3dCam.pos.x,
				s3dCam.pos.y,
				s3dCam.pos.z
			);
	}

	public inline function stopTracking() {
		targetEntity.val = null;
	}
}
