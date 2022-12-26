package en.util.item;

import hxbit.NetworkHost;
import net.transaction.TransactionFactory;
import hxd.Res;
import cherry.soup.EventSignal.EventSignal1;
import en.Item.ItemPresense;
import hxbit.NetworkSerializable;

class InventoryCell implements NetworkSerializable {

	@:isVar
	@:s public var item( default, set ) : en.Item;
	@:s public var containmentEntity : Entity;
	@:s public var type : ItemPresense;

	public var onSetItem : EventSignal1<Item>;

	function setPresense( item : Item, presense : ItemPresense ) {
		item.itemPresense = presense;
	}

	function set_item( v : en.Item ) {
		if ( onSetItem != null ) onSetItem.dispatch( v );
		if ( v != null ) setPresense( v, type );
		return item = v;
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public function new( type : ItemPresense, containmentEntity : Entity ) {
		this.type = type;
		this.containmentEntity = containmentEntity;
		enableAutoReplication = true;
	}

	/**
		client-side
	**/
	public function swapItemsWith( cell : InventoryCell ) {
		TransactionFactory.itemsSwap( this, cell, ( r ) -> Res.sfx.snap.play( 0.4 ) );
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer, ?finalize ) @:privateAccess {
		host.unregister( this, ctx, finalize );
		if ( item != null )
			host.unregister( item, ctx, finalize );
	}

	public function alive() {
		onSetItem = new EventSignal1();
	}
}
