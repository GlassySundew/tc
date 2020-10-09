package ui.player;

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
	public var inventory: Inventory;
	public var craft: Crafting;
	public var configMap: Map<String, TmxLayer>;

	var leftTop: SideCont;

	public function new(parent: Layers) {
		super();

		var r = new Reader();
		r.resolveTSX = getTsx(new Map(), r);
		configMap = r.read(Xml.parse(Res.loader.load(Const.LEVELS_PATH + "ui.tmx").entry.getText())).getLayersByName();

		parent.add(this, Const.DP_UI);
		inventory = new Inventory(configMap, this);
		this.add(inventory, Const.DP_UI);
		
		leftTop = new SideCont(Top, Left, this);
		this.add(leftTop,  Const.DP_UI);

		craft = new Crafting(configMap, this);
		this.add(craft, Const.DP_UI);

		// new StatView(Health, leftTop);

		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.side);
		style.addObject(leftTop);
	}

	override function sync(ctx: RenderContext) {
		super.sync(ctx);
	}

	override function onRemove() {
		super.onRemove();
	}
}
