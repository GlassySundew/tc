package core.debug;

/**
	обертка над доступом к полю для ImGuiMacro.wref
**/
abstract class Accessor<T> {

	public var val( get, set ) : T;

	function get_val() : T {
		return null;
	}

	function set_val( val : T ) : T {
		return null;
	}

	public function new() {}
}
