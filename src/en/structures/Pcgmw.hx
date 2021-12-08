package en.structures;

import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Pcgmw extends Structure {
	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructuresKind ) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("pcgmw");
		}

		super(x, z, tmxObj, cdbEntry);
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}
}
