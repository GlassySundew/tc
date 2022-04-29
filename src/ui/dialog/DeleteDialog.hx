package ui.dialog;

import ui.domkit.TextLabelComp;
import h2d.Flow;
import dn.Process;
import h2d.Object;
import ui.dialog.SaveManager.Mode;
import hxd.Event;

class DeleteDialog extends Dialog {
	public function new( name : String, activateEvent : Event -> Void, mode : Mode, saveMan : SaveManager, ?parent : Object, ?parentProcess : Process ) {
		super( mode, saveMan, parent, parentProcess );

		var dialogFlow = new Flow( h2dObject );
		dialogFlow.verticalAlign = Middle;
		dialogFlow.horizontalSpacing = 6;

		var deleteText = new TextLabelComp( 'Are you sure?', Assets.fontPixel, dialogFlow );

		var yesBut = new TextButton( "yes", ( e ) -> {
			destroy();

			SaveManager.generalDelete( name );

			Client.inst.delayer.addF(() -> {
				refreshSaves();
				saveMan.refreshEntries();
			}, 10 );
		}, 0xbe3434, 0x6d2a45, dialogFlow );
		var noBut = new TextButton( "no", ( e ) -> {
			destroy();
		}, dialogFlow );
	}
}