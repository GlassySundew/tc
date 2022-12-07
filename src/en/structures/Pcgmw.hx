package en.structures;

import format.tmx.Data.TmxObject;
import util.Assets;

class Pcgmw extends Structure {

	public function new( ?tmxObj : TmxObject ) {
		super( tmxObj );
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
