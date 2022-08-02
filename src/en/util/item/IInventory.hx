package en.util.item;

import en.Item.ItemPresense;
import ui.core.InventoryGrid.InventoryCellFlowGrid;

interface IInventory {
	public var cellFlowGrid : InventoryCellFlowGrid;
	public var isVisible( get, never ) : Bool;
	public var type( get, never ) : ItemPresense;
}
