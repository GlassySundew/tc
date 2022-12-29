package net;

import core.VO;
import hxbit.Serializable;
import cherry.soup.EventSignal.EventSignal1;
import hxbit.NetworkSerializable;

@:forward
abstract NSVO<T>( NSVOBase<T> ) {

	@:to inline function toT() : T {
		return this.val;
	}

	@:to inline function toNS() : NetworkSerializable {
		return this;
	}

	public function new( v : T ) {
		this = new NSVOBase( v );
	}
}

/**
	Network Serializable Value Object
	обёртка над примитивным типом(Int, String, Enum, Float) для поддержки syncBack
**/
@:allow( net.NSVO )
class NSVOBase<T> extends VOBase<T> implements NetworkSerializable {

	override function get_val() : T {
		return maskVal;
	}

	override function set_val( v : T ) : T {
		super.set_val( v );

		if ( v == maskVal ) return v;
		return maskVal = v;
	}

	@:s private var maskVal( default, set ) : Dynamic;

	function set_maskVal( v : Dynamic ) : Dynamic {
		return val = maskVal = v;
	}

	private function new( ?v : T ) {
		super( v );
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
