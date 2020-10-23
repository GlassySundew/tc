package en.items;

import h2d.Object;

class Plant extends en.Item {
	public function new(?type:ItemsKind, ?parent:Object) {
		super(type, parent);
		spr.set("seaweed");
		// getObjectByNamegame.delayer.addF(start, 1);
	}
}
