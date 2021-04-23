package en.structures.hydroponics;

import format.tmx.Data.TmxObject;
import hxd.Event;
import hxd.Key in K;
/** Использует inv как хранилище для растений **/
class Hydroponics extends Structure {
	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, hydroponics);
	}

	override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			spr.anim.registerStateAnim("hydroponics0", 1, 1, function() return invGrid != null ? invGrid.itemCout == 0 : true);
			spr.anim.registerStateAnim("hydroponics1", 0, 1, function() return invGrid != null ? invGrid.itemCout > 0 : true);
		}
		super.init(x, z, tmxObj);

		interactable = true;

		// inv.giveItem(new en.Item(axe));
		#if debug
		// invGrid.giveItem(new en.Item(plant), this, true, false);
		// invGrid.giveItem(new en.Item(plant), this, true, false);
		// invGrid.giveItem(new en.Item(plant), this, true, false);
		#end

		#if !headless
		interact.onTextInput = function(e : Event) {
			if ( K.isPressed(K.E) ) dropGrownPlant();
		}
		#end
	}

	function dropGrownPlant() {
		// inv.grid[0][0].item = dropItem(inv.grid[0][0].item);
		if ( invGrid.itemCout > 0 ) {
			dropAllItems();
		}

		interactable = false;
	}

	override function update() {
		super.update();
		// if ( hxd.Key.isDown(hxd.Key.W) ) mesh.rotate(0, 0.1, 0);
	}
}
