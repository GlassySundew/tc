package en;

import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {
	public function new( ?x : Float = 0, ?z : Float = 0, sprite : String, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		if ( sprFrame == null ) sprFrame = {
			group : "",
			frame : 0
		};

		sprFrame.group = sprite;

		super(x, z, tmxObj, cdbEntry);
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {

		super.init(x, z, tmxObj);
		// mesh.isLong=true;
		// mesh.isoHeight=mesh.isoWidth=1;
	}

	public override function alive() {
		if ( spr == null && sprFrame.group != "null" ) {
			spr = new HSprite(Assets.structures, sprFrame.group, entParent);
		}
		super.alive();
		if ( tmxObj != null && tmxObj.properties.exists("interactable") ) {
			interactable = tmxObj.properties.getBool("interactable");
		}
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
