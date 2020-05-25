package en.structures.hydroponics;

import en.objs.IsoTileSpr;
import h3d.col.Bounds;
import h3d.Vector;
import h3d.Matrix;
import format.tmx.Data.TmxObject;

class Hydroponics extends Interactive {
	var m:Matrix;

	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set("hydroponics");
		}
		super(x, z, tmxObj);
		// sprOffX += 12;
		// sprOffY += 4;
		mesh.isLong = true;

		mesh.verts = {
			right: {x: 17, z: -7},
			down: {x: -17, z: -7},
			left: {x: -17, z: 7},
			up: {x: 17, z: 7}
		};

		mesh.renewDebugPts();
		bottomAlpha = -25;
		
	}

	// override function update() {
	// 	super.update();
	// }

	override function postUpdate() {
		super.postUpdate();

		// var up = Boot.inst.s3d.camera.up;
		// var vec = Boot.inst.s3d.camera.pos.sub(Boot.inst.s3d.camera.target);
		// @:privateAccess mesh.qRot.initRotateMatrix(Matrix.lookAtX(vec, up));
	}
}
