package ui.player;

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
class Inventory extends Object {
	public var invGrid: InventoryGrid;
	public var belt: Belt;

	public var player(get, never): Player;

	inline function get_player() return Player.inst;

	var configMap: Map<String, TmxLayer>;

	public var sprInv: HSprite;

	var ca: dn.heaps.Controller.ControllerAccess;

	public var base: Bitmap;

	public function new(configMap: Map<String, TmxLayer>, ?parent: Object) {
		super(parent);
		this.configMap = configMap;
		ca = Main.inst.controller.createAccess("inventory");
		sprInv = new HSprite(Assets.ui, this);
		sprInv.set("inventory");

		var gridPt = configMap.get("inventory").getObjectByName("grid");
		sprInv.visible = !sprInv.visible;

		var textLabel = new ui.TextLabel("Inventory", Assets.fontPixel, sprInv);
		textLabel.minWidth = Std.int(sprInv.tile.width * Const.SCALE);
		textLabel.scale(.5);
		// textLabel.horizontalAlign = Middle;
		textLabel.paddingTop = 2 + textLabel.outerHeight >> 1; // пиздец
		// trace(Std.int(gridPt.x), Std.int(gridPt.y), gridPt.properties.getInt("tileWidth"), gridPt.properties.getInt("tileHeight"),
		// 	gridPt.properties.getInt("width"), gridPt.properties.getInt("height"), gridPt.properties.getInt("gapX"), gridPt.properties.getInt("gapY"));
		invGrid = new InventoryGrid(Std.int(gridPt.x), Std.int(gridPt.y), gridPt.properties.getInt("tileWidth"), gridPt.properties.getInt("tileHeight"),
			gridPt.properties.getInt("width"), gridPt.properties.getInt("height"), gridPt.properties.getInt("gapX"), gridPt.properties.getInt("gapY"), sprInv);
		// Освобождаем последний ряд для Belt
		for (i in invGrid.interGrid[invGrid.interGrid.length - 1])
			i.remove();
		belt = new Belt(this);

		// invGrid.giveItem(new en.items.Scepter(0, 0));
		// items[0].push(new en.items.Ore(invGrid0x, invGrid0y, Iron, base));
	}

	function recenter() {
		sprInv.x = Std.int((getS2dScaledWid() - sprInv.tile.width) / 2);
		sprInv.y = Std.int((getS2dScaledHei() - sprInv.tile.height) / 2);
	}

	public function toggleVisible() {
		sprInv.visible = !sprInv.visible;
		recenter();
	}

	override function onRemove() {
		super.onRemove();
		sprInv.remove();
		sprInv.tile.dispose();
		sprInv.remove();
	}
}
