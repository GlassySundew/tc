package en.structures;

import util.Assets;
import format.tmx.Data.TmxObject;

class SleepingPod extends Structure {

	public function new( ?tmxObj : TmxObject ) {
		super( tmxObj );
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
