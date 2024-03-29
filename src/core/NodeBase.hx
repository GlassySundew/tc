package core;

import cherry.soup.EventSignal.EventSignal1;

abstract class NodeBase<T : NodeBase<T>> {

	var parent( default, set ) : T;
	var children : Array<T>;

	function set_parent( p : T ) {
		if ( parent != null )
			parent.removeChild( cast this );
		if ( p != null )
			p.addChild( cast this );
		return parent = p;
	}

	public inline function new( ?parent : T ) {
		children = [];
		this.parent = parent;
	}

	function removeChild( n : T ) {
		children.remove( n );
	}

	function addChild( n : T ) {
		children.push( n );
	}
}
