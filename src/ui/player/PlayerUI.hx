package ui.player;

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
	public var inventory:Inventory;
	var leftTop:SideCont;

	public function new(parent:Layers) {
		super();

		parent.add(this, Const.DP_UI);
		inventory = new Inventory(this);
		this.add(inventory, 3);
		leftTop = new SideCont(Top, Left, this);
		this.add(leftTop, 2);
		// new StatView(Health, leftTop);

		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.side);
		style.addObject(leftTop);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
	}
	override function onRemove() {
		super.onRemove();
	}
}

@:uiComp("sideCont")
class SideCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <sideCont content-halign = '${hor}' content-valign = '${vert}'> </sideCont>;
	
	public function new(vert:FlowAlign, hor:FlowAlign, ?parent) {
		super(parent);
		initComponent();
	}
}
