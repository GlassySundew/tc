package en.structures;

import format.tmx.Data.TmxObject;

class Back_Door extends Door {
	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);
	}

	public override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("back_door");
		}
		super.init(x, z, tmxObj);
		mesh.flipX();
	}
}
