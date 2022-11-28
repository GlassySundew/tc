package en.structures;

import util.Assets;
import format.tmx.Data.TmxObject;

class SleepingPod extends Structure {

	public function new( ?tmxObj : TmxObject, ?cdbEntry : Data.EntityKind ) {
		super( tmxObj, cdbEntry );
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
