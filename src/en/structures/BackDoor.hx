package en.structures;

import format.tmx.Data.TmxObject;

class BackDoor extends Door {

	override function alive() {
		super.alive();
		mesh.flipX();
	}
}
