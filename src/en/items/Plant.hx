package en.items;

import h2d.Object;

class Plant extends Item {
	public function new(?parent:Null<Object>) {
		super(parent);
		spr.set("seaweed");
		displayText = "Seaweed";
		// getObjectByNamegame.delayer.addF(start, 1);
	}
}
