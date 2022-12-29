package net.transaction;

import net.transaction.ItemTransaction.ItemPourTransaction;
import net.transaction.ItemTransaction.SplitItemInHalfTransaction;
import en.util.item.InventoryCell;
import net.transaction.ItemTransaction.ItemSwapTransaction;
import net.transaction.ItemTransaction.MoveItemToInvTransaction;
import net.transaction.Transaction.TransactionResult;
import ui.core.InventoryGrid;

class TransactionFactory {

	public static function itemsSwap( from : InventoryCell, to : InventoryCell, ?cb : TransactionResult -> Void ) {
		var transaction = new ItemSwapTransaction( from, to );
		Main.inst.cliCon.val.sendTransaction( transaction, cb );
	}

	/**
		split an item in half
	**/
	public static function itemSplit( from : InventoryCell, to : InventoryCell, ?cb : TransactionResult -> Void ) {
		var transaction = new SplitItemInHalfTransaction( from, to );
		Main.inst.cliCon.val.sendTransaction( transaction, cb );
	}

	/**
		pour same items type from one cell to another
	**/
	public static function itemPour( from : InventoryCell, to : InventoryCell, ?cb : TransactionResult -> Void ) {
		var transaction = new ItemPourTransaction( from, to );
		Main.inst.cliCon.val.sendTransaction( transaction, cb );
	}

	public static function transferToOtherInv( from : InventoryCell, to : InventoryGrid, ?cb : TransactionResult -> Void ) {
		var transaction = new MoveItemToInvTransaction( from, to );
		Main.inst.cliCon.val.sendTransaction( transaction, cb );
	}
}
