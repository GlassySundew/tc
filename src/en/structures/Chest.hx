package en.structures;

import en.Item.ItemPresense;
import ui.core.InventoryGrid;
import ui.core.InventoryGrid.InventoryCellFlowGrid;
import dn.heaps.input.ControllerAccess;
import en.player.Player;
import en.util.ItemUtil;
import format.tmx.Data.TmxObject;
import game.client.ControllerAction;
import game.client.GameClient;
import h2d.Object;
import hxd.Event;
import ui.player.Inventory;

class Chest extends Structure {

	public var chestWin : ChestWin;

	var ca : ControllerAccess<ControllerAction>;

	public function new( x = 0., y = 0., z = 0., ?tmxObj : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super( x, y, z, tmxObj, cdbEntry );
		interactable = true;

		inventory = new InventoryGrid( 5, 5, Chest, this );

		ItemUtil.resolveJsonItemStorage( tmxObj.properties.getString( "items" ), inventory );
	}

	public override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super.init( x, y, z, tmxObj );
	}

	override function alive() {
		super.alive();

		ca = Main.inst.controller.createAccess();

		GameClient.inst.delayer.addF(() -> {
			try {
				cellFlowGrid = new InventoryCellFlowGrid( inventory, 20, 20 );

				if ( Player.inst != null && Player.inst.pui != null ) {
					chestWin = new ChestWin( cellFlowGrid, Player.inst.pui.root );
					chestWin.containmentEntity = this;
				}
			} catch( e ) {
				trace( e );
			}
		}, 1 );

		interact.onTextInputEvent.add(
			( e : Event ) -> {
				if ( ca.isPressed( Action ) ) {
					
					if ( !Player.inst.pui.inventory.win.visible ) Player.inst.pui.inventory.toggleVisible();
					chestWin.toggleVisible();
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

	override function get_type() return ItemPresense.Chest;

	// public var chestEntity :
	public function new( ?cellGrid : InventoryCellFlowGrid, ?parent : Object ) {
		super( false, cellGrid, parent );

		windowComp.window.windowLabel.shadowed_text.text = "Chest";
	}

	override function initLoad() {
		super.initLoad();
	}

	override function toggleVisible() {
		if ( !win.visible ) {
			win.x = Player.inst.pui.inventory.windowComp.window.getSize().width + Player.inst.pui.inventory.win.x + 4;
			win.y =
				Player.inst.pui.inventory.win.y +
				( Player.inst.pui.inventory.windowComp.window.getSize().height -
					windowComp.window.getSize().height ) / 2;
		}
		super.toggleVisible();
	}
}
