package ui.player;

import en.Entity;
import en.Item;
import ui.core.ItemSprite;
import en.Item.ItemPresense;
import en.player.Player;
import en.util.ItemUtil;
import en.util.item.InventoryCell;
import net.Client;
import util.Cursors;

class ItemCursorHolder extends InventoryCell {

	override function setPresense( item : Item, presense : ItemPresense ) {
		if ( item.itemPresense == PlayerBelt ) return;
		else super.setPresense( item, presense );
	}

	// override function get_item() return beltItem != null ? beltItem : item;
	public function new( contEntity : Entity ) {
		super( Cursor, contEntity );
	}

	override function alive() {
		super.alive();
		// Main.inst.delayer.addF(() -> {
		// 	if ( cast( containmentEntity, Player ).uid == Client.inst.uid )
		// 		onSetItem.add( ( item : Item ) -> {
		// 			if ( item != null && item.itemPresense == PlayerBelt && !Player.inst.pui.inventory.isVisible ) return;

		// 			ItemUtil.enableWindowCellGridInteractivity( item != null );

		// 			if ( this.item != null ) {
		// 				if ( this.item.itemSprite != null ) {
		// 					Cursors.removeObjectFromCursor( this.item.itemSprite );
		// 					this.item.onAmountChanged.remove( refreshCursors );
		// 				}
		// 				this.item.onPlayerRemove.dispatch();
		// 			}

		// 			if ( item != null ) {
		// 				if ( item.itemSprite == null ) @:privateAccess {
		// 					var spr = new ItemSprite( item, Boot.inst.s2d );
		// 					spr.restraintSize();
		// 					spr.needReflow = true;
		// 					spr.sync( Boot.inst.s2d.renderer );
		// 				}
		// 				item.onAmountChanged.add( refreshCursors );
		// 				item.itemSprite.x = item.itemSprite.y = 5;
		// 				Cursors.passObjectForCursor( item.itemSprite );
		// 				item.itemSprite.item.onPlayerHold.dispatch();
		// 				Player.inst.pui.belt.deselectCells();
		// 			}
		// 		} );
		// }, 1 );
	}

	inline static function refreshCursors( ?v ) Cursors.refreshCursors();
}
