package en.structures;

import format.tmx.Data.TmxObject;

class Sleeping_Pod extends Structure {
	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("sleeping_pod");
		}
		super(x, z, tmxObj, cdbEntry);
		interactable = true;

		mesh.isLong = true;
		mesh.isoWidth = 2;
		mesh.isoHeight = 1;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
