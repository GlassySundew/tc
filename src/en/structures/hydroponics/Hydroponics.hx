package en.structures.hydroponics;

import util.Util;
import en.spr.EntityView;
import format.tmx.Data.TmxObject;
import hxd.Event;
import hxd.Key in K;
import util.Assets;

/** Использует inv как хранилище для растений **/
class Hydroponics extends Structure {

	public function new( ?tmxObj : TmxObject ) {
		super( tmxObj );
	}

	override function init() {
		eSpr = new EntityView(
			this,
			Assets.structures,
			Util.hollowScene
		);
		eSpr.spr.anim.registerStateAnim(
			"hydroponics0",
			1,
			1,
			function ()
				return
					inventoryModel.inventory != null ? inventoryModel.inventory.itemCount == 0 : true
		);
		eSpr.spr.anim.registerStateAnim(
			"hydroponics1",
			0,
			1,
			function ()
				return
					inventoryModel.inventory != null ? inventoryModel.inventory.itemCount >= 0 : true
		);

		super.init();

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
		if ( inventoryModel.inventory.itemCount > 0 ) {
			dropAllItems();
		}

		interactable = false;
	}

	override function update() {
		super.update();
	}
}
