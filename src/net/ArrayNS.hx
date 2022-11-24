package net;

import cherry.soup.EventSignal;
import hxbit.Serializable;
import hxbit.NetworkSerializable;
import haxe.iterators.ArrayIterator;

@:forward
abstract ArrayNS<T : Serializable>( ArrayNSBase<T> ) {

	@:to function toIter() : ArrayIterator<T> {
		return cast this.array.iterator();
	}

	public function new() {
		this = new ArrayNSBase();
	}
}

@:allow( net.ArrayNS )
class ArrayNSBase<T : Serializable> implements NetworkSerializable {

	@:s final array : Array<Dynamic> = [];

	public var onPush : EventSignal1<T> = new EventSignal1<T>();
	public var onRemove : EventSignal1<T> = new EventSignal1<T>();

	private function new() {
		enableAutoReplication = true;
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public inline function filter( f : T -> Bool ) : Array<Dynamic> {
		return
		inline array.filter( f );
	}

	public inline function push( item : T ) pushRpc( item );

	@:rpc( immediate )
	function pushRpc( item : Dynamic ) {
		array.push( item );
		onPush.dispatch( item );
	}

	public inline function remove( item : T ) removeRpc( item );

	@:rpc( immediate )
	function removeRpc( item : Dynamic ) {
		array.remove( item );
		onRemove.dispatch( item );
	}
}
