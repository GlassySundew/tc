package ui.player;

import h2d.Flow;
import ui.WindowComp;
import en.player.Player;
import h2d.Object;
import ui.InventoryGrid.CellGrid;
/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends NinesliceWindow {
	public static var ALL : Array<Inventory> = [];

	public var player(get, never) : Player;

	inline function get_player() return Player.inst;

	var ca : dn.heaps.Controller.ControllerAccess;

	public var invGrid : CellGrid;
	public var containmentEntity : Entity;

	public function new( ?removeLastRow : Bool = true, ?invGrid : CellGrid, ?parent : Null<Object> ) {
		super(( tile, bl, bt, br, bb, parent ) -> {
			new InventoryComp(tile, bl, bt, br, bb, removeLastRow, invGrid, parent);
		}, parent);

		this.invGrid = invGrid;

		windowComp.window.windowLabel.labelTxt.text = "Inventory";

		ca = Main.inst.controller.createAccess("inventory");

		toggleVisible();
	}

}
