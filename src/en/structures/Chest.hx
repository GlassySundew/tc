package en.structures;

import ui.Window;
import tools.Util;
import ui.player.PlayerUI;
import h2d.Flow;
import en.player.Player;
import hxd.Event;
import hxd.Key;
import ui.player.Inventory;
import format.tmx.Data.TmxObject;

class Chest extends Structure {
	public var inventory : Inventory;

	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);
		ca = Main.inst.controller.createAccess("chest");

		var conf = resolveMap("ui.tmx").getLayersByName();
		for (i in conf) i.localBy(i.getObjectByName("window"));

		initInv(conf.get("chest").getObjectByName("grid"));

		inv.giveItem(Item.fromCdbEntry(axe), this);

		var configMap = resolveMap("ui.tmx").getLayersByName();
		for (i in configMap) i.localBy(i.getObjectByName("window"));

		inventory = new Inventory(configMap, inv, Level.inst.game.root);
		inventory.containmentEntity = this;

		inventory.headingLabel.textLabel.labelTxt.text = "Chest";
		inventory.headingLabel.center();

		interact.onTextInputEvent.add((e : Event) -> {
			if ( ca.aPressed() ) {
				Player.inst.ui.inventory.win.visible = true;
				// if ( Player.inst.ui.inventory.win.visible == false ) {
				inventory.win.visible = true;
				inventory.bringOnTopOfALL();
				Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
				// }
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
