package en;

import util.Util;
import en.spr.EntitySprite;
import util.Assets;

// Just an helping indicator that should show if structure can be placed on
class StructureGhost extends Structure {

	public var canBePlaced : Bool = false;

	public function new( cdbEntry : Data.EntityKind ) {
		eSpr = new EntitySprite( this,
			Assets.structures,
			Util.hollowScene,
			'${Data.entity.get( cdbEntry ).id}'
		);

		super( cdbEntry );

		toBeCollidedAgainst = false;

		interact.onPushEvent.removeAll();
		interact.onOverEvent.removeAll();
		interact.onOutEvent.removeAll();
		interact.visible = false;

		eSpr.spr.alpha = .75;

		model.cd.setS( "colorMaintain", 1 / 0 );

		// GameClient.inst.applyTmxObjOnEnt(this);
	}

	public function isValidToPlace() {
		// if ( checkCollsAgainstAll( false ) ) {
		// 	turnRed();
		// 	canBePlaced = false;
		// } else {
		// 	turnGreen();
		// 	canBePlaced = true;
		// }
	}

	public function turnGreen() {
		eSpr.colorAdd.setColor( 0x29621e );
	}

	public function turnRed() {
		eSpr.colorAdd.setColor( 0xbe3434 );
	}

	override function applyItem( item : Item ) {}

	override function emitDestroyItem( item : Item ) {}

	override function updateInteract() {}

	override function postUpdate() {
		super.postUpdate();
		isValidToPlace();
	}
}
