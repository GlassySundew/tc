package en.items;

import h2d.Object;

// enum Type {
// 	Iron;
// 	Copper;
// }
class Ore extends en.Item {
	var type: Type;

	public function new(cdbEntry: Data.ItemsKind, ?parent: Object) {
		// if (spr == null)

		// switch type {
		// 	case Iron:
		// 		displayText = "Iron Ore";
		// 		spr.set("item_iron_ore");
		// 	default:
		// }

		super(cdbEntry, parent);
		spr = new HSprite(Assets.items, this);
	}
}
