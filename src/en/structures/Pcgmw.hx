package en.structures;

import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Pcgmw extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set("pcgmw");
		}

		super(x, z, tmxObj);

	}



	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
