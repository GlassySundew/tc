package ui.player;

import format.tmx.Data.TmxLayer;
import h2d.Object;

class Crafting extends Object {
	var configMap: Map<String, TmxLayer>;
	var sprInv: HSprite;

	public function new(configMap: Map<String, TmxLayer>, ?parent: Object) {
		super(parent);
		this.configMap = configMap;
		toggleVisible();
		sprInv = new HSprite(Assets.ui, this);
        sprInv.set("crafting");
        
        var textLabel = new ui.TextLabel("Crafting", Assets.fontPixel, sprInv);
		textLabel.minWidth = Std.int(sprInv.tile.width * Const.SCALE);
		textLabel.scale(.5);
		textLabel.paddingTop = 2 + textLabel.outerHeight >> 1; // пиздец
	}

	public function toggleVisible() {
		visible = !visible;
		// recenter();
	}
}
