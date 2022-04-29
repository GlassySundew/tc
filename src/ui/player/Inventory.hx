package ui.player;

import h2d.Object;
import ui.InventoryGrid.UICellGrid;
import ui.domkit.InventoryComp;
/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends NinesliceWindow {

	public var cellGrid : UICellGrid;
	public var containmentEntity : Entity;

	public function new( ?removeLastRow : Bool = true, cellGrid : UICellGrid, ?parent : Null<Object> ) {
		this.cellGrid = cellGrid;
		super("window", InventoryComp, parent, cellGrid, removeLastRow);

		windowComp.window.windowLabel.labelTxt.text = "Inventory";
		toggleVisible();
	}
}
