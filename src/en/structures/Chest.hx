package en.structures;

import ui.InventoryGrid;
import en.player.Player;
import format.tmx.Data.TmxObject;
import h2d.Object;
import hxd.Event;
import ui.InventoryGrid.UICellGrid;
import ui.player.Inventory;

class Chest extends Structure {
	public var chestWin : ChestWin;

	var ca : dn.heaps.Controller.ControllerAccess;
	

	public function new( ?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super(x, z, tmxObj, cdbEntry);
		interactable = true;

		// inventory = new 

		inventory = new InventoryGrid(5, 5, null, this);
		
		// addingData.Item from props only when first loaded (with no serialization)
		for ( prop in tmxObj.properties.keys() ) {
			var split = prop.split(":");
			if ( split.length > 1 && split[0] == "item" ) {
				var item = Item.fromCdbEntry(Data.item.resolve(split[1]).id, this);
				item.amount = tmxObj.properties.getInt(prop);
				inventory.giveItem(item);
			}
		}
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
	}

	override function alive() {
		super.alive();

		ca = Main.inst.controller.createAccess("chest");

		cellGrid = new UICellGrid(inventory, 20, 20);

		GameClient.inst.delayer.addF(() -> {
			if ( Player.inst != null && Player.inst.ui != null ) {
				chestWin = new ChestWin(cellGrid, Player.inst.ui.root);
				chestWin.containmentEntity = this;
			}
		}, 1);

		interact.onTextInputEvent.add(
			( e : Event ) -> {
				if ( ca.aPressed() ) {
					if ( !Player.inst.ui.inventory.win.visible ) Player.inst.ui.inventory.toggleVisible();
					chestWin.toggleVisible();
					// Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
				}
			}
		);
	}

	override function postUpdate() {
		super.postUpdate();

		if (
			Player.inst != null
			&& Player.inst.isMoving
			&& !isInPlayerRange()
			&& chestWin != null
			&& chestWin.win.visible == true
		) {
			chestWin.toggleVisible();
		}
	}

	override function dispose() {
		super.dispose();
		if ( chestWin != null ) chestWin.destroy();
	}
}

class ChestWin extends Inventory {

	// public var chestEntity : 
	public function new( ?cellGrid : UICellGrid, ?parent : Object ) {
		super(false, cellGrid, parent);

		windowComp.window.windowLabel.labelTxt.text = "Chest";
	}

	override function initLoad() {
		super.initLoad();
	}

	override function toggleVisible() {
		if ( !win.visible ) {
			win.x = Player.inst.ui.inventory.windowComp.window.getSize().width + Player.inst.ui.inventory.win.x + 4;
			win.y = Player.inst.ui.inventory.win.y + (Player.inst.ui.inventory.windowComp.window.getSize().height - windowComp.window.getSize().height) / 2;
		}
		super.toggleVisible();
	}
}
