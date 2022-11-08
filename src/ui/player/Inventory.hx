package ui.player;

import en.Entity;
import en.Item.ItemPresense;
import en.util.ItemUtil;
import en.util.item.IInventory;
import h2d.Object;
import ui.core.InventoryGrid.InventoryCellFlowGrid;
import ui.domkit.InventoryComp;

/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends NinesliceWindow implements IInventory {

	public var cellFlowGrid : InventoryCellFlowGrid;
	public var containmentEntity : Entity;
	public var type( get, never ) : ItemPresense;

	function get_type() return PlayerInventory;

	public function new( ?removeLastRow : Bool = true, cellGrid : InventoryCellFlowGrid, ?parent : Null<Object> ) {
		this.cellFlowGrid = cellGrid;
		super( "window", InventoryComp, parent, cellGrid, removeLastRow );

		windowComp.window.windowLabel.shadowed_text.text = "Inventory";
		toggleVisible();
		ItemUtil.inventories.push( this );
	}

	override function onDispose() {
		super.onDispose();
		ItemUtil.inventories.remove( this );
	}
}
