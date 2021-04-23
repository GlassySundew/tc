package ui.player;

import en.player.Player;
import h2d.Object;
import ui.InventoryGrid.CellGrid;
/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends Window {
	public static var ALL : Array<Inventory> = [];

	public var player(get, never) : Player;

	inline function get_player() return Player.inst;

	var ca : dn.heaps.Controller.ControllerAccess;

	public var headingLabel : TextLabel;

	public var invGrid : CellGrid;
	public var containmentEntity : Entity;

	public function new(?invGrid : CellGrid, ?parent : Object) {
		spr = new HSprite(Assets.ui);
		spr.set("inventory");

		super(parent);
		ALL.push(this);
		this.invGrid = invGrid;

		ca = Main.inst.controller.createAccess("inventory");

		headingLabel = new ui.TextLabel("Inventory", Assets.fontPixel, spr);
		headingLabel.scale(.5);

		headingLabel.x = uiConf.get("inventory").getObjectByName("sign").x;
		headingLabel.y = uiConf.get("inventory").getObjectByName("sign").y;
		headingLabel.center();

		win.addChild(invGrid);
		// invGrid.giveItem(new en.items.Scepter(0, 0));
		// items[0].push(new en.items.Ore(invGrid0x, invGrid0y, Iron, base));

		createDragable("inventory");
		createCloseBut("inventory");
		recenter();
		toggleVisible();
		bringOnTopOfALL();

		
	}

	public override function bringOnTopOfALL() {
		super.bringOnTopOfALL();

		ALL.remove(this);
		ALL.unshift(this);
	}

	override function toggleVisible() {
		clampInScreen();
		super.toggleVisible();
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
	}
}
