package ui.player;

import en.player.Player;
import h2d.Layers;
import h2d.RenderContext;
import h2d.domkit.Style;
import h3d.Vector;
import hxd.System;
import tools.Settings.*;
import tools.Settings;
import ui.InventoryGrid.CellGrid;

class PlayerUI extends Layers {
	public var inventory : Inventory;
	public var belt : Belt;

	public var craft : Crafting;

	var leftTop : SideCont;

	public function new(parent : Layers) {
		super();

		var gridConf = uiConf.get("inventory").getObjectByName("grid");

		Player.inst.invGrid = new CellGrid(gridConf.properties.getInt("width"), gridConf.properties.getInt("height"), gridConf.properties.getInt("tileWidth"),
			gridConf.properties.getInt("tileHeight"));

		for (j in 0...Player.inst.invGrid.grid.length) {
			for (i in 0...Player.inst.invGrid.grid[j].length) {
				var tempInter = Player.inst.invGrid.grid[j][i];
				tempInter.inter.x = gridConf.x + i * (gridConf.properties.getInt("tileWidth") + gridConf.properties.getInt("gapX"));
				tempInter.inter.y = gridConf.y + j * (gridConf.properties.getInt("tileHeight") + gridConf.properties.getInt("gapY"));
			}
		}

		parent.add(this, Const.DP_BG);
		inventory = new Inventory(Player.inst.invGrid, this);
		inventory.containmentEntity = Player.inst;

		inventory.win.x = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.x : Settings.params.inventoryCoordRatio.x * Main.inst.w();
		inventory.win.y = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.y : Settings.params.inventoryCoordRatio.y * Main.inst.h();

		if ( Settings.params.inventoryVisible ) inventory.toggleVisible();

		// Освобождаем последний ряд для Belt
		for (i in inventory.invGrid.grid[inventory.invGrid.grid.length - 1]) i.remove();

		this.add(inventory.win, Const.DP_UI);

		belt = new Belt(Player.inst.invGrid.grid[Player.inst.invGrid.grid.length - 1], this);
		this.add(belt, Const.DP_UI);

		leftTop = new SideCont(Top, Left, this);
		this.add(leftTop, Const.DP_UI);

		craft = new Crafting(this);
		this.add(craft.win, Const.DP_UI);

		// new StatView(Health, leftTop);

		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.side);
		style.addObject(leftTop);
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);
	}

	override function onRemove() {
		super.onRemove();
	}
}
