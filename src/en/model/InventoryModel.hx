package en.model;

import ui.core.InventoryGrid;
import ui.player.ItemCursorHolder;
import net.NetNode;

class InventoryModel extends NetNode {

	@:s public var holdItem : ItemCursorHolder;
	@:s public var inventory : InventoryGrid;
}
