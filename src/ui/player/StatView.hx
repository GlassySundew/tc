package ui.player;

import h2d.Mask;
import h2d.Object;
import ui.player.PlayerState.StatName;

class StatView extends Object {
	var stat:StatName;
	var slider:HSlider;

	public function new(stat:StatName, ?parent) {
		super(parent);
		this.stat = stat;
		var signSpr = new HSprite(Assets.ui, this);
		signSpr.set(stat + "_sign");
		slider = new HSlider(this);
	}
}

class HSlider extends Mask {
	public function new(?parent) {
		super(100, 12, parent);
	}
}
