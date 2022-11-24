package en;

import utils.Util;
import en.spr.EntitySprite;
import utils.Assets;
import format.tmx.Data.TmxObject;

class EntityView extends Structure {

	@:s var spriteGroup : String;

	public function new( x = 0., y = 0., z = 0., sprite : String, ?tmxObj : TmxObject, ?cdbEntry : Data.EntityKind ) {
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
			Util.hollowScene,
			spriteGroup
		);
		super.alive();
	}

	override function postUpdate() {
		super.postUpdate();
	}

	
}
