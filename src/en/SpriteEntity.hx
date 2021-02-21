package en;

import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {
	public function new(?x : Float = 0, ?z : Float = 0, sprite : String, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set(sprite);
		}

		super(x, z, tmxObj, cdbEntry);
		if ( tmxObj.properties.exists("interactable") ) {
			interactable = tmxObj.properties.getBool("interactable");
		}

		
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
