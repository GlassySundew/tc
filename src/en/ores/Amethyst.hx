package en.ores;

import format.tmx.Data.TmxObject;

class Amethyst extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set("amethyst");
		}
		super(x, z, tmxObj);
		// sprOffX += -spr.tile.width;
		// sprOffY -= Const.GRID_HEIGHT * .5;
	}

	// override function update() {
	// 	super.update();
	// }

	override function postUpdate() {
		super.postUpdate();

		// mesh.z += 1 / Camera.ppu;
	}
}
