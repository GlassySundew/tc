package en.structures;

import format.tmx.Data.TmxObject;
import util.Assets;

class Pcgmw extends Structure {

	public function new( ?tmxObj : TmxObject, ?cdbEntry : Data.EntityKind ) {
		super( tmxObj, cdbEntry );
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
