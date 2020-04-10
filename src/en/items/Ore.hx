package en.items;

import h2d.Object;

enum Type {
	Iron;
	Copper;
}

class Ore extends Item {
	var type:Type;

	public function new(?x:Float = 0, ?y:Float = 0, type:Type, ?parent:Object) {
		if (spr == null)
			spr = new HSprite(Assets.items, parent);
		this.type = type;

		super(x, y, parent);
	}

	override function init() {
		super.init();
		switch type {
			case Iron:
				displayText = "Iron Ore";
				spr.set("item_iron_ore");
			default:
		}
	}
}
