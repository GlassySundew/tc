package en.player;

class PlayerState {
	public static var inst : PlayerState;

	public var onShip(get, never) : Bool;

	function get_onShip() {
		return if ( location != null ) StringTools.startsWith(location, "ship"); else null;
	}

	public var location : String;
	public var stats = new Map<StatName, Float>();

	public function new() {
		inst = this;
		stats = [Health => 100];
	}
}

enum abstract StatName(String) from String to String {
	var Health = "health";
	// var Hunger = "hunger";
	// var Humanity = "humanity";
}
