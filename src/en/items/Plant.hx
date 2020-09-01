package en.items;

import h2d.Object;

class Plant extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Null<Object>) {
		super(x, y, parent);
		spr.set("seaweed");
		displayText = "Seaweed";
	}
}
