package ui.dialog;

import dn.Process;
import h2d.Flow;
import h2d.Object;
import ui.domkit.TextLabelComp;

class DeleteDialog extends Dialog {

	public function new( name : String, ?parent : Object, ?parentProcess : Process ) {
		super( parent, parentProcess );

		new TextLabelComp( 'Are you sure?', Assets.fontPixel, contentFlow );

		var horizontalFlow = new Flow(contentFlow);
		horizontalFlow.layout = Horizontal;
		horizontalFlow.horizontalSpacing = 10;

		new TextButton( "yes", ( e ) -> {
			destroy();

			SaveManager.generalDelete( name );

			Client.inst.delayer.addF(() -> {
				refreshSaves();
			}, 10 );
		}, 0xd36363, 0x855a5a, horizontalFlow );

		new TextButton( "no", ( e ) -> {
			destroy();
		}, horizontalFlow );

		centrizeContent();
	}
}
