package en.items;

import h2d.Object;

class GraviTool extends Item {
	public function new(?parent:Object) {
		super( parent);
		spr.set("item_gravity_manipulator");
		displayText = "Gravitation Pickaxe";
	}
}
