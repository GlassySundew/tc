package en;

// Just an helping indicator that should show if structure can be placed on
class StructureGhost extends Structure {
	public var canBePlaced : Bool = false;

	public function new( cdbEntry : Data.StructuresKind ) {
		spr = new HSprite(Assets.structures, entParent);
		spr.set('${Data.structures.get(cdbEntry).id}');

		super(0, 0, cdbEntry);
		
		toBeCollidedAgainst = false;

		interact.onPushEvent.removeAll();
		interact.onOverEvent.removeAll();
		interact.onOutEvent.removeAll();
		interact.visible = false;

		spr.alpha = .75;

		cd.setS("colorMaintain", 1 / 0);

		Level.inst.game.applyTmxObjOnEnt(this);
	}

	public function checkIfValidToPlace() {
		if ( checkCollsAgainstAll(false) ) {
			turnRed();
			canBePlaced = false;
		} else {
			turnGreen();
			canBePlaced = true;
		}
	}

	public function turnGreen() {
		colorAdd.setColor(0x29621e);
	}

	public function turnRed() {
		colorAdd.setColor(0xbe3434);
	}

	override function applyItem( item : Item ) {}

	override function emitDestroyItem( item : Item ) {}

	override function updateInteract() {}

	override function postUpdate() {
		super.postUpdate();
		checkIfValidToPlace();
	}
}
