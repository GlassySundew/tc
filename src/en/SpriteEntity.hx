package en;

import util.Util;
import en.spr.EntitySprite;
import util.Assets;
import format.tmx.Data.TmxObject;

class SpriteEntity extends Structure {

	@:s var spriteGroup : String;

	public function new( sprite : String, ?tmxObj : TmxObject, ?cdbEntry : Data.EntityKind ) {
		spriteGroup = sprite;
		super( tmxObj, cdbEntry );
	}

	override function init() {

		super.init();
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
