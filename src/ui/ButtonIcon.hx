package ui;

import dn.Process;
import h2d.Tile;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("cont")
class ButtonIconCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =  <cont>
		 	<bitmap src={tile} public id="icon">
				<flow public id="activateTextFlow">
					<text text="E" public id="activateText" />
					</flow>
				</bitmap>
		</cont>;
		public function new(?tile:Tile, ?parent) {
			super(parent);
			initComponent();
		}
}

class ButtonIcon {
	public var container:ButtonIconCont;
	public var buttonSpr:HSprite;

	public var centerFlow:Flow;
	var style:Style;
	var p:Object;

	public function new(x = 0., y = 0., p:Object) {
		this.p = p;
		centerFlow = new h2d.Flow(p);
		Main.inst.root.add(centerFlow, Const.DP_UI);
		// Main.inst.root.under(centerFlow);
		buttonSpr = new HSprite(Assets.ui, p);
		buttonSpr = Assets.ui.h_getAndPlay("keyboard_icon");
		Game.inst.root.add(buttonSpr, 10);
		buttonSpr.anim.setSpeed(0.025);
		container = new ButtonIconCont(centerFlow);
		// container.icon.alpha = 0.;
		// 	container.icon.alpha = 1;
		buttonSpr.visible = false;
		buttonSpr.setCenterRatio();
		style = new h2d.domkit.Style();
		style.addObject(container);
		style.load(hxd.Res.domkit.buttonIcon);
		container.activateTextFlow.x -= container.activateText.textWidth / 2 - 1;
		container.activateTextFlow.y -= container.activateText.textHeight / 2 + 2;
		// container.activateTextFlow.y -= ;
		buttonSpr.onFrameChange = function() {
			container.activateTextFlow.paddingTop = if (buttonSpr.frame == 1) 3; else 0;
		};
	}

	public function dispose() {
		buttonSpr.remove();
		centerFlow.remove();
	}
}
