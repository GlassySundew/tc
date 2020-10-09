package en.items;

import h2d.Object;

class Scepter extends Item {
	public function new( ?parent:Object) {
		super(parent);
		spr.set("scepter");
		displayText = "Scepter of Necromancy";
		spr.scale(.5);
	}
}
