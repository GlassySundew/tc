package core;

import cherry.soup.EventSignal.EventSignal1;

/**
	dispatchable propertly, a wrapper around a value, dispatch callbacks 
	on value
**/
class DispProp<T> {

	public var val( default, set ) : T;

	function set_val( v : T ) {
		if ( val == v ) return v;
		onValue.dispatch( v );
		return val = v;
	}

	public final onValue = new EventSignal1<T>();

	public function new( val : T ) {
		this.val = val;
	}
}
