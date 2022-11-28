package en.structures;

import format.tmx.Data.TmxObject;

class BackDoor extends Door {

	public function new(?tmxObj : TmxObject) {
		super(tmxObj);
	}


	// override function alive() {
	// 	super.alive();
	// 	eSpr.mesh.flipX();
	// }
}
