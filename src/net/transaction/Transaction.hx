package net.transaction;

import hxbit.Serializable;
import hxbit.NetworkSerializable;

enum abstract TransactionResult( Bool ) from Bool to Bool {

	var Success = true;
	var Failure = false;
}

/**
	концепт: на клиенте при совершении действия, требующего серверной 
	валидации, создается транзакция, действие происходит одновременно 
	с отправкой транзакции, не дожидаясь результата, и если транзакция 
	не 	проходит валижацию на сервере, она должна быть отменена, 
**/
class Transaction implements Serializable {

	@:s public var previous : Transaction;
	@:s public var next : Transaction;

	public function new( ?prev : Transaction ) {
		if ( prev != null ) {
			previous = prev;
			prev.next = this;
		}
	}

	public function commit() : TransactionResult {
		throw "not supported";
	}

	public function validate() : TransactionResult {
		throw "not supported";
	}
}
