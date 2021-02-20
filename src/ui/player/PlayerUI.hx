package ui.player;

import ui.InventoryGrid.CellGrid;
import format.tmx.Data.TmxLayer;
import hxd.Res;
import format.tmx.Data.TmxMap;
import format.tmx.Reader;
import h2d.Object;
import h2d.Layers;
import h2d.RenderContext;
import en.player.Player;
import h3d.Vector;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

class PlayerUI extends Layers {
	public var inventory : Inventory;
	public var belt : Belt;

	public var craft : Crafting;
	public var configMap : Map<String, TmxLayer>;

	var leftTop : SideCont;

	public function new(parent : Layers) {
		super();

		configMap = resolveMap("ui.tmx").getLayersByName();
		for (i in configMap) i.localBy(i.getObjectByName("window"));

		var gridConf = configMap.get("inventory").getObjectByName("grid");

		Player.inst.invGrid = new CellGrid(gridConf.properties.getInt("width"), gridConf.properties.getInt("height"), gridConf.properties.getInt("tileWidth"),
			gridConf.properties.getInt("tileHeight"));

		for (j in 0...Player.inst.invGrid.grid.length) {
			for (i in 0...Player.inst.invGrid.grid[j].length) {
				var tempInter = Player.inst.invGrid.grid[j][i];
				tempInter.inter.x = gridConf.x + i * (gridConf.properties.getInt("tileWidth") + gridConf.properties.getInt("gapX"));
				tempInter.inter.y = gridConf.y + j * (gridConf.properties.getInt("tileHeight") + gridConf.properties.getInt("gapY"));
			}
		}
		
		parent.add(this, Const.DP_UI);
		inventory = new Inventory(configMap, Player.inst.invGrid, this);
		inventory.containmentEntity = Player.inst;
		for (i in inventory.invGrid.grid[inventory.invGrid.grid.length - 1]) i.remove();

		this.add(inventory.win, Const.DP_UI);

		belt = new Belt(Player.inst.invGrid.grid[Player.inst.invGrid.grid.length - 1], this);
		this.add(belt, Const.DP_UI);

		leftTop = new SideCont(Top, Left, this);
		this.add(leftTop, Const.DP_UI);

		craft = new Crafting(configMap, this);
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
