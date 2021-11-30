package en.structures;

import h3d.scene.Mesh;
import h2d.Tile;
import h3d.col.Point;
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

	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind ) {
		super(x, z, tmxObj, cdbEntry);

		invGrid = new CellGrid(5, 5, 25, 25, this);

		// adding items from props only when first loaded (with no serialization)
		for ( prop in tmxObj.properties.keys() ) {
			var split = prop.split(":");
			if ( split.length > 1 && split[0] == "item" ) {
				var item = Item.fromCdbEntry(Data.items.resolve(split[1]).id);
				item.amount = tmxObj.properties.getInt(prop);
				invGrid.giveItem(item, this);
			}
		}
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
		ca = Main.inst.controller.createAccess("chest");

		#if !headless
		Game.inst.delayer.addF(() -> {
			inventory = new ChestWin(invGrid,
				Player.inst.ui.root);
			inventory.containmentEntity = this;
		}, 2);
		#end

		interact.onTextInputEvent.add(( e : Event ) -> {
			if ( ca.aPressed() ) {
				if ( !Player.inst.ui.inventory.win.visible ) Player.inst.ui.inventory.toggleVisible();
				inventory.toggleVisible();
				// Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
			}
		});
	}

	override function postUpdate() {
		super.postUpdate();

		if ( Player.inst != null
			&& Player.inst.isMoving()
			&& !isInPlayerRange()
			&& inventory != null
			&& inventory.win.visible == true ) {
			inventory.toggleVisible();
		}
	}

	override function dispose() {
		super.dispose();
		if ( inventory != null ) inventory.destroy();
	}
}

class ChestWin extends Inventory {
	public function new( ?invGrid : CellGrid, ?parent : Object ) {
		super(false, invGrid, parent);

		windowComp.window.onDrag.add(( x, y ) -> {
			Settings.params.chestCoordRatio.x = win.x / Main.inst.w();
			Settings.params.chestCoordRatio.y = win.y / Main.inst.h();
		});

		windowComp.window.windowLabel.labelTxt.text = "Chest";
	}

	override function initLoad( ?parent : Object ) {
		super.initLoad(parent);
	}

	override function toggleVisible() {
		win.x = Settings.params.chestCoordRatio.toString() == new Vector(-1, -1).toString() ? win.x : Settings.params.chestCoordRatio.x * Main.inst.w();
		win.y = Settings.params.chestCoordRatio.toString() == new Vector(-1, -1).toString() ? win.y : Settings.params.chestCoordRatio.y * Main.inst.h();

		super.toggleVisible();
	}
}
