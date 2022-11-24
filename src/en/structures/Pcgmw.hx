package en.structures;

import format.tmx.Data.TmxObject;
import utils.Assets;

class Pcgmw extends Structure {

	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.EntityKind ) {
		super( x, z, tmxObj, cdbEntry );
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
