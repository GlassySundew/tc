package en.items;

import h2d.Object;

enum Type {
	Iron;
	Copper;
}

class Ore extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, type:Type, ?parent:Object) {
		if (spr == null)
			spr = new HSprite(Assets.items, parent);
		switch type {
			case Iron:
				spr.set("item_iron_ore");
			default:
		}
		super(x, y, parent);
	}
}
