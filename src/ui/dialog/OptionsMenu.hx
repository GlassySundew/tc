package ui.dialog;

import h2d.RenderContext;
import hxd.Event;
import h2d.Object;
import h2d.Flow;


class OptionsMenu extends FocusMenu {
	var nicknameInput : ui.TextInput;

	public function new( ?parent : Object ) {
		super( parent ); 

		centrizeContent();

		var mm = new ShadowedText( Assets.fontPixel, contentFlow );
		mm.scale( 1.5 );
		mm.text = "Options";

		var horFlow = new Flow( contentFlow );
		horFlow.layout = Horizontal;
		horFlow.verticalAlign = Top;

		var nickname = new ShadowedText( Assets.fontPixel, horFlow );
		nickname.text = "username: ";

		nicknameInput = new ui.TextInput( Assets.fontPixel, horFlow );
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
