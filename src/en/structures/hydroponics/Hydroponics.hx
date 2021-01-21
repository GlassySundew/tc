package en.structures.hydroponics;

import en.player.Player;
import ui.player.Inventory;
import ui.InventoryGrid.InventoryCell;
import hxd.Event;
import en.items.Plant;
import en.objs.IsoTileSpr;
import h3d.Vector;
import format.tmx.Data.TmxObject;
import hxd.Key in K;
/**
	Использует inv как хранилище для растений
**/
class Hydroponics extends Structure {
	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.anim.registerStateAnim("hydroponics0", 1, 1, function() return inv != null ? inv.itemCout == 0 : true);
			spr.anim.registerStateAnim("hydroponics1", 0, 1, function() return inv != null ? inv.itemCout > 0 : true);
		}

		super(x, z, tmxObj, hydroponics);

		interactable = true;

		// inv.giveItem(new en.Item(axe));
		inv.giveItem(new en.Item(plant), true, false);
		inv.giveItem(new en.Item(plant), true, false);
		inv.giveItem(new en.Item(plant), true, false);

		#if !headless
		interact.onTextInput = function(e : Event) {
			if ( K.isPressed(K.E) ) dropGrownPlant();
		}
		#end
	}

	function dropGrownPlant() {
		// inv.grid[0][0].item = dropItem(inv.grid[0][0].item);
		if ( inv.itemCout > 0 ) {
			dropAllItems();
		}

		interactable = false;
		// if (plantCont != null) {
		// 	interactable = false;
		// 	new FloatingItem(mesh.x + 1, mesh.z - 1, plantContainer).bumpAwayFrom(this, .05);
		// 	plantContainer = null;
		// }
	}
}
