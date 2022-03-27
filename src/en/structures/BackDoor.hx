package en.structures;

import format.tmx.Data.TmxObject;

class BackDoor extends Door {
	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super(x, z, tmxObj, cdbEntry);
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
		mesh.flipX();
	}
}
