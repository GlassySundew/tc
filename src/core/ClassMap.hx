package core;

@:forward
abstract ClassMap<T, K>( Map<Dynamic, K> ) {

	public function new() {
		this = new Map<Dynamic, K>();
	}

	@:arrayAccess
	function get( v : T ) {
		return this.get( '$v' );
	}

	@:arrayAccess
	function set( k : T, v : K ) {
		return this.set( '$k', v );
	}
}
