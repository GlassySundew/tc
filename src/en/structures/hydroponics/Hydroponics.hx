package en.structures.hydroponics;

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
class Hydroponics extends Interactive {
	
	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);

			spr.anim.registerStateAnim("hydroponics0", 1, 1, function() return inv != null ? inv.itemCout == 0 : true);
			spr.anim.registerStateAnim("hydroponics1", 0, 1, function() return inv != null ? inv.itemCout > 0 : true);
		}

		super(x, z, tmxObj);
		
		interactable = true;
		mesh.isLong = true;
		mesh.isoWidth = 2;
		mesh.isoHeight = 1;
		mesh.renewDebugPts();

		inv.giveItem(new Plant());
		inv.giveItem(new Plant());
		inv.giveItem(new Plant());
		inv.giveItem(new Plant()); 

		// plantCont = new Plant(this);

		interact.onTextInput = function(e:Event) {
			if (K.isPressed(K.E))
				dropGrownPlant();
		}
	}

	function dropGrownPlant() {
		// inv.grid[0][0].item = dropItem(inv.grid[0][0].item);
		if (inv.itemCout > 0) {
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
