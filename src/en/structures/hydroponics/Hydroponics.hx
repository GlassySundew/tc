package en.structures.hydroponics;

import en.spr.EntitySprite;
import format.tmx.Data.TmxObject;
import hxd.Event;
import hxd.Key in K;
import utils.Assets;

/** Использует inv как хранилище для растений **/
class Hydroponics extends Structure {

	public function new( x = 0., y = 0., z = 0., ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super( x, y, z, tmxObj, hydroponics );
	}

	override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		eSpr = new EntitySprite(
			this,
			Assets.structures,
			hollowScene
		);
		eSpr.spr.anim.registerStateAnim( "hydroponics0", 1, 1, function () return cellFlowGrid != null ? cellFlowGrid.itemCount == 0 : true );
		eSpr.spr.anim.registerStateAnim( "hydroponics1", 0, 1, function () return cellFlowGrid != null ? cellFlowGrid.itemCount > 0 : true );

		super.init( x, y, z, tmxObj );

		interactable = true;

		// inv.giveItem(new en.Item(axe));
		#if debug
		// cellGrid.giveItem(new en.Item(plant), this, true, false);
		// cellGrid.giveItem(new en.Item(plant), this, true, false);
		// cellGrid.giveItem(new en.Item(plant), this, true, false);
		#end

		interact.onTextInput = function ( e : Event ) {
			if ( K.isPressed( K.E ) ) dropGrownPlant();
		}
	}

	function dropGrownPlant() {
		// inv.grid[0][0].item = dropItem(inv.grid[0][0].item);
		if ( cellFlowGrid.itemCount > 0 ) {
			dropAllItems();
		}

		interactable = false;
	}

	override function update() {
		super.update();
	}
}
