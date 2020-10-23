package en.items;

import h2d.Object;

class GraviTool extends en.Item {
	public function new(?type:ItemsKind, ?parent:Object) {
		super(type, parent);
		spr.set("item_gravity_manipulator");
		displayText = "Gravitation Pickaxe";
	}
}
