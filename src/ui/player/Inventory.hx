package ui.player;

import ui.domkit.InventoryComp;
import h2d.Flow;
import ui.domkit.WindowComp;
import en.player.Player;
import h2d.Object;
import ui.InventoryGrid.CellGrid;
/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends NinesliceWindow {
	public var player(get, never) : Player;

	inline function get_player() return Player.inst;

	var ca : dn.heaps.Controller.ControllerAccess;

	public var cellGrid : CellGrid;
	public var containmentEntity : Entity;

	public function new( ?removeLastRow : Bool = true, cellGrid : CellGrid, ?parent : Null<Object> ) {
		super("window", InventoryComp, parent, cellGrid, removeLastRow);

		this.cellGrid = cellGrid;

		windowComp.window.windowLabel.labelTxt.text = "Inventory";

		ca = Main.inst.controller.createAccess("inventory");

		toggleVisible();
	}
}
