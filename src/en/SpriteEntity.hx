package en;

import utils.Assets;
import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {

	@:s var spriteGroup : String;

	public function new( ?x : Float = 0, ?z : Float = 0, sprite : String, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		spriteGroup = sprite;
		super( x, z, tmxObj, cdbEntry );
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {

		super.init( x, z, tmxObj );
		// mesh.isLong=true;
		// mesh.isoHeight=mesh.isoWidth=1;
	}

	public override function alive() {
		if ( spr == null ) {
			spr = new HSprite( Assets.structures, spriteGroup, hollowScene );
		}
		super.alive();
		if ( tmxObj != null && tmxObj.properties.exists( "interactable" ) ) {
			interactable = tmxObj.properties.getBool( "interactable" );
		}
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
