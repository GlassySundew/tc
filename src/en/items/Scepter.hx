package en.items;

import h2d.Object;

class Scepter extends en.Item {
	public function new(?type:ItemsKind, ?parent:Object) {
		super(type, parent);
		spr.set("scepter");
		displayText = "Scepter of Necromancy";
		spr.scale(.5);
	}
}
