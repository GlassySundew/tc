package en.structures.hydroponics;

import format.tmx.Data.TmxObject;

class Hydroponics extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set("hydroponics");
		}
		super(x, z, tmxObj);

		// sprOffX += -spr.tile.width;
		// sprOffY += Const.GRID_HEIGHT * .5;
		// spr.scaleY=-1;
		// mesh.scaleZ = -1;
		// mesh.rotate(0, M.toRad(-30), 0);
		mesh.setRotationAxis(0, 100, 100, -rotAngle);
		mesh.rotate(0, 0, M.toRad(90));
		bottomAlpha = 20;
		// footY += Level.inst.data.tileHeight / 2;
	}

	// override function update() {
	// 	super.update();
	// }

	override function postUpdate() {
		super.postUpdate();
		// mesh.rotate(0, 0.01, 0);
		// mesh.z += 1 / Camera.ppu;
	}
}
