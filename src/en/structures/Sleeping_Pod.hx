package en.structures;

import format.tmx.Data.TmxObject;

class Sleeping_Pod extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("sleeping_pod");
		}
		super(x, z, tmxObj);
		interactable = true;
		
		mesh.isLong = true;
		mesh.isoWidth = 2;
		mesh.isoHeight = 1;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
