package en.structures;

import format.tmx.Data.TmxObject;

class Back_Door extends Door {
	public function new(?x:Int = 0, ?z:Int = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("back_door");
		}
		super(x, z, tmxObj);
		mesh.flipX();
	}
}
