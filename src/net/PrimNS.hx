package net;

import hxbit.Serializable;
import cherry.soup.EventSignal.EventSignal1;
import hxbit.NetworkSerializable;

@:forward
abstract PrimNS<T>( PrimNSBase<T> ) {

	@:to inline function toT() : T {
		return this.val;
	}

	@:to inline function toNS() : NetworkSerializable {
		return this;
	}

	public function new(v : T) {
		this = new PrimNSBase(v);
	}
}

/**
	Primitive Network Serializable
	обёртка над примитивным типом(Int, String, Enum, Float) для поддержки syncBack
**/
@:allow( net.PrimNS )
class PrimNSBase<T> implements NetworkSerializable {

	public var val( get, set ) : T;

	function get_val() : T {
		return maskVal;
	}

	function set_val( v : T ) : T {
		if ( v == maskVal ) return v;
		return maskVal = v;
	}

	@:s private var maskVal( default, set ) : Dynamic;

	function set_maskVal( v : Dynamic ) : Dynamic {
		onVal.dispatch( v );
		return maskVal = v;
	}

	public var onVal : EventSignal1<T> = new EventSignal1();

	private function new( ?v : T ) {
		maskVal = v;
		enableAutoReplication = true;
	}

	public function alive() {
		enableAutoReplication = true;
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public function toString() {
		return '$val';
	}
}
