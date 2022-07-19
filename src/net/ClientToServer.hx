package net;

import hxbit.Serializable;
import hxbit.NetworkSerializable;

@:forward
abstract AClientToServer<V>( CClientToServer<V> ) from CClientToServer<V> to CClientToServer<V> {

	/** 
		@param condition если возвращает true, то на клиент переменная не будет синхронизироваться
	**/
	public function new( value : V, ?condition : Void -> Bool ) {
		this = new CClientToServer( value, condition );
	}
}

class CClientToServer<V> implements NetworkSerializable {

	var maskValue : V;

	@:s
	var value( default, set ) : Dynamic;

	function set_value( v : V ) {
		if ( clientToServerCond == null || !clientToServerCond() )
			maskValue = v;

		return value = v;
	}

	// function set_value( value : V ) : V {
	// 	return 1;
	// }
	public var clientToServerCond : Void -> Bool;

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public inline function setValue( v : V ) : V {
		maskValue = v;
		// if ( clientToServerCond != null && !clientToServerCond() )
		value = v;

		return maskValue;
	}

	public inline function getValue() : V return maskValue;

	public function new( value : V, ?condition : Void -> Bool ) {
		clientToServerCond = condition == null ? () -> false : condition;

		setValue( value );
		enableAutoReplication = true;
	}
}

@:forward
abstract AClientToServerFloat( CClientToServerFloat ) from CClientToServerFloat to CClientToServerFloat {

	@:op( a + b ) inline function add( v : Float ) {
		return this.setValue( toFloat() + v );
	}

	@:op( a += b ) inline function addAssign( v : Float ) {
		return this.setValue( toFloat() + v );
	}

	@:op( a - b ) inline function substract( v : Float ) {
		return this.setValue( toFloat() - v );
	}

	@:op( a -= b ) inline function substractAssign( v : Float ) {
		return this.setValue( toFloat() - v );
	}

	@:to public function toInt() : Int {
		return cast( toFloat(), Int );
	}

	@:to public inline function toFloat() : Float {

		return this.getValue();
	}

	@:to
	public function toString() {
		return '${this.getValue()}';
	}

	// @:from static function fromFloat( v : Float ) {
	// 	return new (v, );
	// }

	/** 
		@param condition если возвращает true, то на клиент переменная не будет синхронизироваться
	**/
	public function new( value : Float, ?condition : Void -> Bool ) {
		this = new CClientToServerFloat( value, condition );
	}
}

/**
	specific client setting var -> server and server sending to  serializable variable
**/
class CClientToServerFloat implements NetworkSerializable {

	var maskValue : Float;

	@:s
	@:increment( 1 )
	var value( default, set ) : Float;

	inline function set_value( v : Float ) {
		if ( clientToServerCond == null || !clientToServerCond() )
			maskValue = v;

		return value = v;
	}

	// function set_value( value : V ) : V {
	// 	return 1;
	// }
	public var clientToServerCond : Void -> Bool;

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	public inline function setValue( v : Float ) : Float {

		maskValue = v;
		// if ( clientToServerCond == null || clientToServerCond() )
		value = v;

		return maskValue;
	}

	public inline function getValue() : Float return maskValue;

	public function new( value : Float, ?condition : Void -> Bool ) {
		clientToServerCond = condition == null ? () -> false : condition;

		setValue( value );
		enableAutoReplication = true;
	}
}
