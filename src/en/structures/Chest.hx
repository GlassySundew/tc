package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import hxd.Event;
import ui.player.Inventory;

class Chest extends Structure {
	public var inventory : Inventory;

	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);
		ca = Main.inst.controller.createAccess("chest");

		initInv(uiConf.get("chest").getObjectByName("grid"));

		inv.giveItem(Item.fromCdbEntry(axe), this);

		inventory = new Inventory(inv, Level.inst.game.root);
		inventory.containmentEntity = this;

		inventory.headingLabel.textLabel.labelTxt.text = "Chest";
		inventory.headingLabel.center();

		interact.onTextInputEvent.add((e : Event) -> {
			if ( ca.aPressed() ) {
				Player.inst.ui.inventory.win.visible = true;
				inventory.win.visible = true;
				inventory.bringOnTopOfALL();
				// Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
			}
		});
	}

	override function postUpdate() {
		super.postUpdate();
		if ( distPx(Player.inst) > Data.structures.get(cdbEntry).use_range ) inventory.win.visible = false;
	}

	override function dispose() {
		super.dispose();
		inventory.destroy();
	}
}
