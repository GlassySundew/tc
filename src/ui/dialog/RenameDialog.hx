package ui.dialog;

import hxd.Key;
import dn.Process;
import h2d.Flow;
import h2d.Object;
import ui.dialog.SaveManager.Mode;


class RenameDialog extends Dialog {
	public function new( name : String, mode : Mode, saveMan : SaveManager, ?parent : Object, ?parentProcess : Process ) {
		super( mode, saveMan, parent, parentProcess );

		var generalFlow = new Flow( h2dObject );
		generalFlow.layout = Vertical;

		var dialogFlow = new Flow( generalFlow );
		dialogFlow.verticalAlign = Middle;
		dialogFlow.padding = 2;

		var dialogText = new ShadowedText( Assets.fontPixel, dialogFlow );
		dialogText.text = 'Enter new save name: ';

		var textInput = new TextInput( Assets.fontPixel, dialogFlow );

		var buttonsFlow = new Flow( generalFlow );
		buttonsFlow.horizontalAlign = Middle;
		buttonsFlow.verticalAlign = Middle;
		buttonsFlow.horizontalSpacing = 2;
		buttonsFlow.minWidth = generalFlow.outerWidth;

		textInput.text = name;
		textInput.onKeyDown = function ( e ) if ( e.keyCode == Key.ENTER ) this.activateEvent.dispatch( e );

		var yesBut = new TextButton( "ok", ( e ) -> {
			this.activateEvent.dispatch( e );
		}, buttonsFlow );
		var noBut = new TextButton( "cancel", ( e ) -> {
			destroy();
		}, buttonsFlow );
	}
}


