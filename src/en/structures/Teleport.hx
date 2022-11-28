package en.structures;

class Teleport extends Door {

	public function new( ?tmxObj : format.tmx.Data.TmxObject ) {
		super( tmxObj );
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
