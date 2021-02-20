package en.ores;

import format.tmx.Data.TmxObject;

class Emerald extends Structure {
	public function new(x : Float = 0, z : Float = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);
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
