package ui.dialog;

import util.Const;
import ui.core.TextButton;
import ui.core.ShadowedText;
import ui.core.TextInput;
import util.Assets;
import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import h2d.Flow;
import h2d.Object;
import hxd.File;
import hxd.Key;
import ui.dialog.Dialog;
import ui.dialog.SaveManager;

class NewSaveDialog extends Dialog {

	var buttonsFlow : Flow;

	public var textInput : TextInput;

	var onSave : String -> Void;

	public function new( onSave : String -> Void, mode : Mode, saveMan : SaveManager, ?parent : Object, ?parentProcess : Process ) {
		super( parent, parentProcess );
		this.onSave = onSave;
		centrizeContent();

		var onActivate = new EventSignal0();

		var dialogFlow = new Flow( contentFlow );
		dialogFlow.verticalAlign = Middle;

		dialogFlow.padding = 2;

		var dialogText = new ShadowedText( Assets.fontPixel, dialogFlow );
		dialogText.text = 'Enter new save name: ';

		textInput = new TextInput( Assets.fontPixel, dialogFlow );
		textInput.backgroundColor = 0x80808080;

		dialogFlow.getProperties( dialogText ).verticalAlign = Top;
		dialogFlow.getProperties( textInput ).verticalAlign = Top;

		textInput.onKeyDown = function ( e ) {
			if ( e.keyCode == Key.ENTER ) {
				onActivate.dispatch();
			}
		}

		buttonsFlow = new Flow( contentFlow );
		buttonsFlow.horizontalSpacing = 5;
		buttonsFlow.minWidth = contentFlow.outerWidth;

		var fileName = "new_save_";
		var i = 0;

		while( File.exists( util.tools.Save.saveDirectory + fileName + i + Const.SAVEFILE_EXT ) )
			i++;

		textInput.text = fileName + i;

		onActivate.add( this.onActivate );

		new TextButton( "ok", ( e ) -> {
			if ( saveMan != null ) {
				saveMan.destroy();
				saveMan = null;
			}
			onActivate.dispatch();
		}, buttonsFlow );

		new TextButton( "cancel", ( e ) -> {
			destroy();
		}, 0x666666, 0x303030, buttonsFlow );

		contentFlow.minWidth = contentFlow.innerWidth;
		contentFlow.minHeight = contentFlow.innerHeight;
	}

	function onActivate() {
		onSave( textInput.text );
		SaveManager.newSave( textInput.text, "100000" );
		destroy();
	}
}
