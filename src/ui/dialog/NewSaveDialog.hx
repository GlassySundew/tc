package ui.dialog;

import hxd.File;
import hxd.Key;
import dn.Process;
import h2d.Object;
import ui.dialog.SaveManager.Mode;
import h2d.Flow;

class NewSaveDialog extends Dialog {
	var buttonsFlow : Flow;

	public var textInput : TextInput;

	public function new( onSave : String -> Void, mode : Mode, saveMan : SaveManager, ?parent : Object, ?parentProcess : Process ) {
		super( mode, saveMan, parent, parentProcess );

		centrizeContent();

		var dialogFlow = new Flow( contentFlow );
		dialogFlow.verticalAlign = Middle;

		dialogFlow.padding = 2;

		var dialogText = new ShadowedText( Assets.fontPixel, dialogFlow );
		dialogText.text = 'Enter new save name: ';

		textInput = new TextInput( Assets.fontPixel, dialogFlow );
		textInput.backgroundColor = 0x80808080;

		addOnSceneAddedCb(() -> {
			dialogFlow.getProperties( dialogText ).verticalAlign = Top;
			dialogFlow.getProperties( textInput ).verticalAlign = Top;
		} );

		textInput.onKeyDown = function ( e ) {
			if ( e.keyCode == Key.ENTER ) {
				this.activateEvent.dispatch( e );
			}
		}

		buttonsFlow = new Flow( contentFlow );
		buttonsFlow.horizontalAlign = Middle;
		// buttonsFlow.verticalAlign = Middle;
		buttonsFlow.horizontalSpacing = 5;
		buttonsFlow.minWidth = contentFlow.outerWidth;

		var fileName = "new_save_";
		var i = 0;

		while( File.exists( tools.Save.saveDirectory + fileName + i + Const.SAVEFILE_EXT ) )
			i++;

		textInput.text = fileName + i;

		this.activateEvent.add( ( e ) -> {

			// mode = New( textInput.text );

			onSave( textInput.text );

			destroy();
		}, 1 );

		var yesBut = new TextButton( "ok", ( e ) -> {
			if ( saveMan != null ) {
				saveMan.destroy();
				saveMan = null;
			}
			this.activateEvent.dispatch( e );
		}, buttonsFlow );
		var noBut = new TextButton( "cancel", ( e ) -> {

			destroy();
		}, buttonsFlow );

		contentFlow.minWidth = contentFlow.innerWidth;
		contentFlow.minHeight = contentFlow.innerHeight;
	}
}
