package en;

import en.spr.EntitySprite;
import utils.Assets;
import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {

	@:s var spriteGroup : String;

	public function new( x = 0., y = 0., z = 0., sprite : String, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		spriteGroup = sprite;
		super( x, y, z, tmxObj, cdbEntry );
	}

	override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {

		super.init( x, y, z, tmxObj );
		// mesh.isLong=true;
		// mesh.isoHeight=mesh.isoWidth=1;
	}

	public override function alive() {
		eSpr = new EntitySprite(
			this,
			Assets.structures,
			spriteGroup,
			hollowScene
		);
		super.alive();
	}

	override function postUpdate() {
		super.postUpdate();
	}

	
}
