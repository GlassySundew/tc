package en.util.item;

import ui.core.InventoryGrid.InventoryCellFlow;
import en.player.Player;
import net.transaction.TransactionFactory;

/**
	client-side collection of item movement operation 
	preparations before sending rpc
**/
class ItemManipulations {

	public static var cursorSwappingConditions : Map<String, InventoryCellFlow -> Bool> = new Map<String, InventoryCellFlow -> Bool>();

	public static function getCursorSwappingCondition( cellFlow : InventoryCellFlow ) : Bool {
		for ( fun in cursorSwappingConditions )
			if ( !fun( cellFlow ) ) return false;
		return true;
	}

	/** 
		finds a cell in player singletone inventory
		and transfers item from cell argument to it
	**/
	public static function toPlayer( cell : InventoryCell ) {
		// предмет либо в поясе либо в сундуке, переносим в основной инвентарь игрока
		var sameItemCell = Player.inst.inventory.findSameItem( cell.item, true );
		// будет неприкольно, если мы добавим предмет самого в себя
		var freeSlot = ( sameItemCell != null ) ? sameItemCell : Player.inst.inventory.getFreeSlot();
		if ( freeSlot != null ) {
			TransactionFactory.transferToOtherInv( cell, Player.inst.inventory, ( r ) -> {
				utils.sfx.Sfx.playItemPickupSnd();
			} );
		}
	}

	/**
		find a cell capable of containing an item from cell argument 
		and put item from cell argument in it 
	**/
	public static function fromPlayerInvToAnyInventory( cell : InventoryCell ) {
		var isAnyChestOpened = ItemUtil.inventories.filter( ( f ) -> f.type == Chest ).length > 0;
		for ( w in ItemUtil.inventories ) {
			if ( w.isVisible && ( !isAnyChestOpened || w.type != PlayerBelt ) && w.type != cell.type ) {
				var sameItemCell = w.cellFlowGrid.inventoryGrid.findSameItem( cell.item, true, true );
				if ( sameItemCell != null ) {
					TransactionFactory.transferToOtherInv( cell, w.cellFlowGrid.inventoryGrid, r -> utils.sfx.Sfx.playItemPickupSnd() );
					return;
				}
			}
		}
		// если мы здесь, значит, что не нашлось пустых ячеек в открытых сундуках и мы кидаем предмет в пояс
		if ( Player.inst.pui.belt.inventory.findSameItem( cell.item, false, true ) != null ) {
			TransactionFactory.transferToOtherInv( cell, Player.inst.pui.belt.inventory, r -> utils.sfx.Sfx.playItemPickupSnd() );
			return;
		}
	}
}
