package en;

import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {
	public function new(?x : Float = 0, ?z : Float = 0, sprite : String, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		if ( sprFrame == null ) sprFrame = {
			group : "",
			frame : 0
		};

		sprFrame.group = sprite;

		super(x, z, tmxObj, cdbEntry);
	}

	override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set(sprFrame.group);
		}
		super.init(x, z, tmxObj);
		// mesh.isLong=true;
		// mesh.isoHeight=mesh.isoWidth=0;
		if ( tmxObj != null && tmxObj.properties.exists("interactable") ) {
			interactable = tmxObj.properties.getBool("interactable");
		}
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
