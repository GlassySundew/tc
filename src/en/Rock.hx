package en;

import format.tmx.Data.TmxObject;

class Rock extends Entity {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null)
			spr = new HSprite(Assets.tiles);

		spr.set("rock");
		super(x, z, tmxObj);

		sprOffX += -spr.tile.width;
		sprOffY += spr.tile.height * .2;

		bottomAlpha = 11;
	}

	// override function update() {
	// 	super.update();
	// }

	override function postUpdate() {
		super.postUpdate();

		// mesh.z += 1 / Camera.ppu;
	}
}
