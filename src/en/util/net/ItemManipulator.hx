package en.util.net;

import en.util.item.InventoryCell;
import hxbit.NetworkSerializable;

class ItemManipulator implements NetworkSerializable {

	var owner : NetworkSerializable;

	public function new( owner : NetworkSerializable ) {
		this.owner = owner;
		enableAutoReplication = true;
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return owner != null ? owner == clientSer : true;
	}

	@:rpc( server )
	public function swapItems( from : InventoryCell, to : InventoryCell ) {
		var temp = to.item;
		to.item = from.item;
		from.item = temp;
	}
}
