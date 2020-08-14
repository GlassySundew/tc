package en.structures;

import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Door extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set("door");
		}
		super(x, z, tmxObj);
		interactable = true;

		mesh.isLong = true;
		mesh.isoWidth = 1.3;
		mesh.isoHeight = 0.4;
		mesh.renewDebugPts();
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
