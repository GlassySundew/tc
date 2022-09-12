package en.structures;

import utils.Assets;
import format.tmx.Data.TmxObject;

class Sleeping_Pod extends Structure {

	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super( x, z, tmxObj, cdbEntry );
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
