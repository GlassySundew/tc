package ui.player;

import ui.domkit.ButtonIconComp;
import dn.Process;
import h2d.Tile;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

class ButtonIcon extends Object {
	public var container:ButtonIconComp;
	public var buttonSpr:HSprite;

	public var centerFlow:Flow;

	var style:Style;

	public function new(x = 0., y = 0., ?p:Object) {
		super(p);
		this.x = x;
		this.y = y;
		centerFlow = new h2d.Flow(this);
		centerFlow.setScale(1 / Const.SCALE);
		Game.inst.root.add(centerFlow, Const.DP_UI);

		buttonSpr = Assets.ui.h_getAndPlay("keyboard_icon", 99999, false, this);
		buttonSpr.anim.setSpeed(0.025 * Game.inst.tmod);

		Game.inst.root.add(this, Const.DP_UI);
		container = new ButtonIconComp(centerFlow);
		buttonSpr.visible = false;
		buttonSpr.setCenterRatio();
		style = new h2d.domkit.Style();
		style.addObject(container);
		style.load(hxd.Res.domkit.buttonIcon);
		container.activateTextFlow.x -= container.activateText.textWidth / 2 - 1;
		container.activateTextFlow.y -= container.activateText.textHeight / 2 + 2;
		buttonSpr.onFrameChange = function() {
			container.activateTextFlow.paddingTop = if (buttonSpr.frame == 1) 3; else 0;
		};
	}

	public function dispose() {
		buttonSpr.remove();
		centerFlow.remove();
	}

	override function onRemove() {
		super.onRemove();
		dispose();
	}
}
