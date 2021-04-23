package en.structures;

import hxd.System;
import en.player.Player;
import format.tmx.Data.TmxObject;
import h2d.Object;
import h3d.Vector;
import hxd.Event;
import tools.Settings;
import ui.InventoryGrid.CellGrid;
import ui.player.Inventory;

class Chest extends Structure {
	public var inventory : ChestWin;

	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);
		// adding items from props only when first loaded (with no serialization)
		for (i in tmxObj.properties.keys()) {
			var split = i.split(":");
			if ( split.length > 1 && split[0] == "items" ) {
				invGrid.giveItem(Item.fromCdbEntry(Data.items.resolve(split[1]).id), this);
			}
		}
	}

	public override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		super.init(x, z, tmxObj);
		ca = Main.inst.controller.createAccess("chest");

		initInv(uiConf.get("chest").getObjectByName("grid"));

		#if !headless
		inventory = new ChestWin(invGrid, Level.inst.game.root);
		inventory.containmentEntity = this;
		#end

		interact.onTextInputEvent.add((e : Event) -> {
			if ( ca.aPressed() ) {
				Player.inst.ui.inventory.win.visible = true;
				inventory.toggleVisible();
				inventory.bringOnTopOfALL();
				// Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
			}
		});
	}

	override function postUpdate() {
		super.postUpdate();

		if ( Player.inst != null
			&& distPx(Player.inst) > Data.structures.get(cdbEntry).use_range
			&& inventory.win.visible == true ) inventory.win.visible = false;
	}

	override function dispose() {
		super.dispose();
		inventory.destroy();
	}
}

class ChestWin extends Inventory {
	public function new(?invGrid : CellGrid, ?parent : Object) {
		super(invGrid, parent);

		dragable.onDrag.add((x, y) -> {
			Settings.params.chestCoordRatio.x = win.x / Main.inst.w();
			Settings.params.chestCoordRatio.y = win.y / Main.inst.h();
		});

		headingLabel.textLabel.labelTxt.text = "Chest";
		headingLabel.center();
	}

	override function toggleVisible() {
		win.x = Settings.params.chestCoordRatio.toString() == new Vector(-1, -1).toString() ? win.x : Settings.params.chestCoordRatio.x * Main.inst.w();
		win.y = Settings.params.chestCoordRatio.toString() == new Vector(-1, -1).toString() ? win.y : Settings.params.chestCoordRatio.y * Main.inst.h();

		super.toggleVisible();
	}
}
