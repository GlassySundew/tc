package net;

import hxbit.Serializable;
import hxbit.NetworkSerializable;

/**
	обёртка над примитивным типом(Int, String, Enum, Float) для поддержки syncBack
**/
class PrimNS<T> implements NetworkSerializable {

	public var val( get, set ) : T;

	function get_val() : T {
		return maskVal;
	}

	function set_val( v : T ) : T {
		return maskVal = v;
	}

	@:s private var maskVal : Dynamic;

	public function new( ?v : T ) {
		maskVal = v;
		enableAutoReplication = true;
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}
}
