package ui.player;

import ui.InventoryGrid.CellGrid;
import ui.s2d.EventInteractive;
import format.tmx.Data.TmxLayer;
import en.items.Scepter;
import en.player.Player;
import h2d.RenderContext;
import h2d.Object;
import en.items.GraviTool;
import ui.player.Belt;
import hxd.Event;
import h2d.Tile;
import h3d.mat.Texture;
import hxd.res.Resource;
import domkit.Macros;
import h2d.domkit.Style;
import h2d.Flow;
import haxe.io.Bytes;
import h2d.Bitmap;
import h2d.ScaleGrid;
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

	public function new(?configMap : Map<String, TmxLayer>, ?invGrid : CellGrid, ?parent : Object) {
		super(configMap, parent);
		ALL.push(this);
		this.configMap = configMap;
		this.invGrid = invGrid;

		ca = Main.inst.controller.createAccess("inventory");
		spr = new HSprite(Assets.ui, win);
		spr.set("inventory");

		headingLabel = new ui.TextLabel("Inventory", Assets.fontPixel, spr);
		headingLabel.scale(.5);

		headingLabel.x = configMap.get("inventory").getObjectByName("sign").x;
		headingLabel.y = configMap.get("inventory").getObjectByName("sign").y;
		headingLabel.center();

		win.addChild(invGrid);
		// Освобождаем последний ряд для Belt
		

		// invGrid.giveItem(new en.items.Scepter(0, 0));
		// items[0].push(new en.items.Ore(invGrid0x, invGrid0y, Iron, base));

		createDragable("inventory");
		createCloseBut("inventory");
		recenter();
		toggleVisible();
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
