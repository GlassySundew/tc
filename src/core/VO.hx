package core;

import cherry.soup.EventSignal;
import cherry.soup.EventSignal.EventSignal1;

@:forward
abstract VO<T>( VOBase<T> ) {

	@:to inline function toT() : T {
		return this.val;
	}

	public inline function new( ?v : T ) {
		this = new VOBase( v );
	}
}

/**
	dispatchable propertly, a wrapper around a value, dispatch callbacks 
	on value
**/
class VOBase<T> {

	@:isVar
	public var val( get, set ) : T;

	function get_val() : T {
		return val;
	}

	function set_val( v : T ) : T {
		if ( val == v ) {
			return v;
		}
		onVal.dispatch( v );
		return val = v;
	}

	private var onVal( get, default ) : EventSignal1<T>;

	function get_onVal() : EventSignal1<T> {
		if ( onVal == null ) onVal = new EventSignal1<T>();
		return onVal;
	}

	public function new( val : T ) {
		this.val = val;
	}

	/**
		if `val` is not null, call `cb` right away, if not - save 
		and call `cb` when `val` becomes not null
	**/
	public function onAppear( cb : T -> Void ) {
		var cbWrapped = null;
		cbWrapped = ( val ) -> {
			if ( val == null ) {
				throw "unsupported behavior";
			} else {
				cb( val );
			}
		};
		if ( val != null )
			cb( val );
		else
			addOnValOnce( cbWrapped );
	}

	public function addOnVal( cb : T -> Void ) {
		onVal.add( cb );
	}

	public function addOnValOnce( cb : T -> Void ) {
		onVal.add( cb, true );
	}
}
