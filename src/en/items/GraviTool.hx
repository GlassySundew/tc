package en.items;

import h2d.Object;

class GraviTool extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		if (spr == null)
			spr = new HSprite(Assets.items, parent);
		spr.set("item_gravity_manipulator");
		super(x, y, parent);
		displayText = "Gravitation Pickaxe";
	}
}
