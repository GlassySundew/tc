package en.items;

import h2d.Object;

// enum Type {
// 	Iron;
// 	Copper;
// }
class Ore extends Item {
	var type:Type;

	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		// if (spr == null)

		// switch type {
		// 	case Iron:
		// 		displayText = "Iron Ore";
		// 		spr.set("item_iron_ore");
		// 	default:
		// }

		super(x, y, parent);
		spr = new HSprite(Assets.items, this);
	}
}
