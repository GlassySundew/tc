package en.items;

import h2d.Object;

class Plant extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Null<Object>) {
		if (spr == null)
			spr = new HSprite(Assets.items, parent);
		spr.set("seaweed");
		super(x, y, parent);
		displayText = "Sea weed";
	}
}
 