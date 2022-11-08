package ui.dialog;

import utils.tools.Settings;
import ui.core.ShadowedText;
import ui.core.TextInput;
import utils.Assets;
import h2d.RenderContext;
import hxd.Event;
import h2d.Object;
import h2d.Flow;

class OptionsMenu extends FocusMenu {

	var nicknameInput : TextInput;

	public function new( ?parent : Object ) {
		super( parent );

		centrizeContent();

		contentFlow.verticalSpacing = 5;

		var mm = new ShadowedText( Assets.fontPixel, contentFlow );
		mm.scale( 1.5 );
		mm.text = "Options";

		contentFlow.addSpacing( 10 );

		var horFlow = new Flow( contentFlow );
		horFlow.layout = Horizontal;
		horFlow.verticalAlign = Top;

		var nickname = new ShadowedText( Assets.fontPixel, horFlow );
		nickname.text = "username: ";

		nicknameInput = new TextInput( Assets.fontPixel, horFlow );
		nicknameInput.text = Settings.params.nickname;
		nicknameInput.onFocusLost = function ( e : Event ) {
			Settings.params.nickname = nicknameInput.text;
			Settings.saveSettings();
		}

		// nicknameInput.onKeyDown = function(e : Event) {
		// 	if ( e.keyCode == Key.ENTER ) {
		// 		Util.nickname = nicknameInput.text;
		// 		Util.saveSettings();
		// 		if ( onRemoveEvent != null ) onRemoveEvent();
		// 	}
		// }
	}

	override function update() {
		super.update();

		// if ( Main.inst.ca.isPressed( Escape ) ) {
		// 	remove();
		// }
	}

	override function onResize() {
		super.onResize();
	}
}
