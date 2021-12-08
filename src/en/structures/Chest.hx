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

	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructuresKind ) {
		super(x, z, tmxObj, cdbEntry);
		interactable = true;

		cellGrid = new CellGrid(5, 5, 25, 25, this);

		// addingData.Items from props only when first loaded (with no serialization)
		for ( prop in tmxObj.properties.keys() ) {
			var split = prop.split(":");
			if ( split.length > 1 && split[0] == "item" ) {
				var item = Item.fromCdbEntry(Data.items.resolve(split[1]).id);
				item.amount = tmxObj.properties.getInt(prop);
				cellGrid.giveItem(item);
			}
		}
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
		ca = Main.inst.controller.createAccess("chest");

		#if !headless
		Game.inst.delayer.addF(() -> {
			if ( Player.inst != null && Player.inst.ui != null ) {
				inventory = new ChestWin(cellGrid,
					Player.inst.ui.root);
				inventory.containmentEntity = this;
			}
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

		if (
			Player.inst != null
			&& Player.inst.isMoving()
			&& !isInPlayerRange()
			&& inventory != null
			&& inventory.win.visible == true
		) {
			inventory.toggleVisible();
		}
	}

	override function dispose() {
		super.dispose();
		if ( inventory != null ) inventory.destroy();
	}
}

class ChestWin extends Inventory {
	public function new( ?cellGrid : CellGrid, ?parent : Object ) {
		super(false, cellGrid, parent);

		windowComp.window.windowLabel.labelTxt.text = "Chest";
	}

	override function initLoad( ?parent : Object ) {
		super.initLoad(parent);
	}

	override function toggleVisible() {
		if ( !win.visible ) {
			win.x = Player.inst.ui.inventory.windowComp.window.getSize().width + Player.inst.ui.inventory.win.x + 4;
			win.y = Player.inst.ui.inventory.win.y + (Player.inst.ui.inventory.windowComp.window.getSize().height - windowComp.window.getSize().height) / 2;
		}
		super.toggleVisible();
	}
}
