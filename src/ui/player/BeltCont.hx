package ui.player;

import en.player.Player;
import en.util.item.InventoryCell;
import en.util.item.ItemManipulations;
import h2d.Font;
import h2d.Object;
import h2d.filter.Shader;
import net.transaction.TransactionFactory;
import shader.CornersRounder;
import ui.core.InventoryGrid.InventoryCellFlow;
import ui.core.ShadowedText;

@:uiComp("beltCont")
class BeltCont extends h2d.Flow implements h2d.domkit.Object {

	static var SRC =
		<beltCont>
			<flow class="backgroundFlow" public id="backgroundFlow" />
			<flow class="itemContainer" public id="itemContainer" />
			<flow class="hotkeyFlow">
				<text class="beltSlotNumber" public id="beltSlotNumber" text={Std.string(slotNumber)} font={font} />
			</flow>
		</beltCont>;

	public function onSelect() {
		ItemManipulations.cursorSwappingConditions.set("beltSelectLock", 
			function ( cellFlow : InventoryCellFlow ) {
				if( (
					Player.inst.pui.inventory.isVisible 
					|| cellFlow.cell.type != PlayerBelt 
				) && cellFlow.cell.item != null ) {
					ItemManipulations.cursorSwappingConditions.remove( "beltSelectLock" );
					Player.inst.inventoryModel.holdItem.item = null;
					TransactionFactory.itemsSwap( Player.inst.inventoryModel.holdItem, cellFlow.cell, r -> util.sfx.Sfx.playItemPickupSnd() );
				}
				return false;
			}
		);
	}

	public function new(?font : Font, ?slotNumber : Int, ?parent) {
		super(parent);
		initComponent();

		ShadowedText.addTextOutlineTo(beltSlotNumber);
		
		var shader = new CornersRounder(4);
		backgroundFlow.filter = new Shader(shader);
	}
}
