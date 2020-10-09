package en.items;

import h2d.Object;

// enum Type {
// 	Iron;
// 	Copper;
// }
class Ore extends Item {
	var type:Type;

	public function new( ?parent:Object) {
		// if (spr == null)

		// switch type {
		// 	case Iron:
		// 		displayText = "Iron Ore";
		// 		spr.set("item_iron_ore");
		// 	default:
		// }

		super(parent);
		spr = new HSprite(Assets.items, this);
	}
}
