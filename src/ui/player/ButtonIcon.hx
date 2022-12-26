package ui.player;

import util.Const;
import dn.heaps.slib.HSprite;
import game.client.GameClient;
import h2d.domkit.Style;
import h2d.Flow;
import h2d.Object;
import ui.domkit.ButtonIconComp;
import util.Assets;

class ButtonIcon extends Object {

	public var container : ButtonIconComp;
	public var buttonSpr : HSprite;

	public var centerFlow : Flow;

	var style : Style;

	public function new( x = 0., y = 0., ?p : Object ) {
		super( p );
		this.x = x;
		this.y = y;
		centerFlow = new h2d.Flow( this );
		centerFlow.setScale( 1 / Const.UI_SCALE );
		GameClient.inst.root.add( centerFlow, Const.DP_UI );

		buttonSpr = Assets.ui.h_getAndPlay( "keyboard_icon", 99999, false, this );
		buttonSpr.anim.setSpeed( 0.025 * GameClient.inst.tmod );

		GameClient.inst.root.add( this, Const.DP_UI );
		container = new ButtonIconComp( centerFlow );
		buttonSpr.visible = false;
		buttonSpr.setCenterRatio();
		container.activateTextFlow.x -= container.activateText.textWidth / 2 - 1;
		container.activateTextFlow.y -= container.activateText.textHeight / 2 + 2;
		buttonSpr.onFrameChange = function () {
			container.activateTextFlow.paddingTop = if ( buttonSpr.frame == 1 ) 3; else 0;
		};
	}

	/**
		Я НЕ ЗНАЮ ПОЧЕМУ НО ВСЕ МАКРО ЛОМАЮТСЯ БЕЗ ЭТОЙ ФУНКЦИИ
	**/
	override function onRemove() {
		super.onRemove();
	}
}
