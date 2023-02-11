package net;

import hxbit.Serializable;
import cherry.soup.EventSignal.EventSignal2;
import cherry.soup.EventSignal.EventSignal1;
import hxbit.NetworkSerializable;

@:forward
abstract NSIntMap<T : Serializable>( NSIntMapBase<T> ) from NSIntMapBase<T> to NSIntMapBase<T> {

	@:to function toMap() : Map<Int, T> {
		return cast this.map;
	}

	@:to function toIterable() : Iterator<T> {
		return this.map.iterator();
	}

	@:to function toKVIterable() : KeyValueIterator<Int, T> {
		return this.map.keyValueIterator();
	}

	@:arrayAccess function get( i : Int ) : T {
		return this.map[i];
	}

	@:arrayAccess function set( i : Int, v : T ) {
		return this.set( i, v );
	}

	public function new() {
		this = new NSIntMapBase();
	}
}

@:allow( net.NSIntMap )
class NSIntMapBase<T : Serializable> extends NetNode {

	@:s final map : Map<Int, Dynamic>;

	public var onSet( default, null ) : EventSignal2<Int, T> = new EventSignal2<Int, T>();
	public var onRemove( default, null ) : EventSignal2<Int, T> = new EventSignal2<Int, T>();

	private function new( ?parent : NetNode ) {
		super();
		map = new Map<Int, Dynamic>();
		enableAutoReplication = true;
	}

	public override function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public inline function set( key : Int, val : T ) setRpc( key, val );

	@:rpc
	function setRpc( key : Dynamic, val : Dynamic ) {
		map[key] = val;
		onSet.dispatch( key, val );
	}

	public inline function remove( key : Int ) : T {
		var item = map[key];
		removeRpc( key );
		return item;
	}

	@:rpc
	function removeRpc( key : Int ) {
		onRemove.dispatch( key, map[key] );
		map.remove( key );
	}
}
