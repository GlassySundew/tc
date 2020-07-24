package en.player;

import format.tmx.Data.TmxObject;

class WebPlayer extends Player {
	public function new(x:Float, z:Float, ?tmxObj:TmxObject) {
		super(x, z, tmxObj);
		game.applyTmxObjOnEnt(this);
		lock();
	}

	override function update() {
		super.update();
	}

	override function postUpdate() {
		super.postUpdate();
	}
	
}
