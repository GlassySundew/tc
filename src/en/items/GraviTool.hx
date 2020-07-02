package en.items;

import h2d.Object;

class GraviTool extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		super(x, y, parent);
		spr.set("item_gravity_manipulator");
		displayText = "Gravitation Pickaxe";
	}
}
