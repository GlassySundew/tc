package net;

import hxbit.NetworkSerializable;
import haxe.Int32;
import hxbit.Serializable;

@:forward
abstract AClientToServer<T>( CClientToServer<T> ) from CClientToServer<T> to CClientToServer<T> {

	@:op( a + b ) inline function add( v : Float ) {
		return this.setValue( cast( toFloat() + v ) );
	}

	@:op( a += b ) inline function addAssign( v : Float ) {
		return this.setValue( cast( toFloat() + v ) );
	}

	@:op( a - b ) inline function substract( v : Float ) {
		return this.setValue( cast( toFloat() - v ) );
	}

	@:op( a -= b ) inline function substractAssign( v : Float ) {
		return this.setValue( cast( toFloat() - v ) );
	}

	@:to public function toInt() : Int {
		return cast( toFloat(), Int );
	}

	@:to public inline function toFloat() : Float {
		if ( Std.isOfType( this.getValue(), Float ) )
			return cast( this.getValue(), Float );
		else
			throw "bad logic : trying to cast AClientToServer to float";
	}

	// @:from static function fromFloat( v : Float ) {
	// 	return new (v, );
	// }

	/** 
		@param condition если возвращает true, то на клиент переменная не будет синхронизироваться
	**/
	public function new( value : T, ?condition : Void -> Bool ) {
		this = new CClientToServer( value, condition );
	}
}

/**
	specific client setting var -> server and server sending to  serializable variable
**/
class CClientToServer<V> implements NetworkSerializable {
	var maskValue : V;
	@:s var value( default, set ) : Dynamic;

	function set_value( v : Dynamic ) {

		if ( clientToServerCond == null || !clientToServerCond() )
			maskValue = v;

		return value = v;
	}

	// function set_value( value : V ) : V {
	// 	return 1;
	// }
	
	public var clientToServerCond : Void -> Bool;

	public function  networkAllow(
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
		clientToServerCond = condition;
		setValue( value );
		enableReplication = true;
	}
}
