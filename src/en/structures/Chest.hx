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
	public var cellFlowGrid : InventoryCellFlowGrid;

	var ca : ControllerAccess<ControllerAction>;

	public function new( ?tmxObj : TmxObject ) {
		super( tmxObj );
		canBeInteractedWith.val = true;

		if ( tmxObj.properties.exists( "items" ) )
			ItemUtil.resolveJsonItemStorage(
				tmxObj.properties.getString( "items" ),
				inventoryModel.inventory
			);
	}

	public override function init() {
		super.init();
	}

	override function alive() {
		super.alive();

		ca = Main.inst.controller.createAccess();
	}

	override function createView() {
		super.createView();

		try {
			cellFlowGrid = new InventoryCellFlowGrid( inventoryModel.inventory, 20, 20 );
			chestWin = new ChestWin( cellFlowGrid, GameClient.inst.root );
			chestWin.containmentEntity = this;
		} catch( e ) {
			trace( e );
		}

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
