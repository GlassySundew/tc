package net.transaction;

import dn.M;
import en.Item;
import ui.core.InventoryGrid;
import net.transaction.Transaction.TransactionResult;
import en.util.item.InventoryCell;

/**
	перенос стопки предмета из одной ячейики в другую
**/
class ItemSwapTransaction extends Transaction {

	@:s var from : InventoryCell;
	@:s var to : InventoryCell;

	public function new( from : InventoryCell, to : InventoryCell, ?prev ) {
		super( prev );
		this.from = from;
		this.to = to;
	}

	override function commit() {
		var temp = to.item;
		to.item = from.item;
		from.item = temp;
		return Success;
	}

	override function validate() : TransactionResult {
		if ( from.item == null && to.item == null ) return Failure;
		commit();
		return Success;
	}
}

/**
	умный сплит предмета и перенос в другой инвентарь
**/
class MoveItemToInvTransaction extends Transaction {

	@:s var from : InventoryCell;
	@:s var to : InventoryGrid;

	public function new( from : InventoryCell, to : InventoryGrid, ?prev ) {
		super( prev );
		this.from = from;
		this.to = to;
	}

	override function commit() : TransactionResult {
		to.giveItem( from );
		return Success;
	}

	override function validate() : TransactionResult {

		commit();
		return Success;
	}
}

/**
	перенести половину стака предметов и перенести 
**/
class SplitItemInHalfTransaction extends Transaction {

	@:s var from : InventoryCell;
	@:s var to : InventoryCell;

	public function new( from : InventoryCell, to : InventoryCell, ?prev ) {
		super( prev );
		this.from = from;
		this.to = to;
	}

	override function commit() : TransactionResult {
		if ( from.item.amount > 1 && to.item == null ) {
			to.item = Item.fromCdbEntry( from.item.cdbEntry, from.containmentEntity, from.item.amount >> 1 );
			from.item.amount = from.item.amount - to.item.amount;
		}
		return Success;
	}

	override function validate() : TransactionResult {
		commit();
		return Success;
	}
}

/**
	дополнить количество предметов из одной ячейки в другую
**/
class ItemPourTransaction extends Transaction {

	@:s var from : InventoryCell;
	@:s var to : InventoryCell;

	public function new( from : InventoryCell, to : InventoryCell, ?prev ) {
		super( prev );
		this.from = from;
		this.to = to;
	}

	override function commit() : TransactionResult {
		var oldAmount = to.item.amount;
		to.item.amount = M.iclamp( from.item.amount + to.item.amount, 0, to.item.stack );
		from.item.amount -= to.item.amount - oldAmount;
		if ( from.item.amount == 0 ) from.item = null;
		return Success;
	}

	override function validate() : TransactionResult {
		commit();
		return Success;
	}
}
