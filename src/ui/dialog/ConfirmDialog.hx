package ui.dialog;

import hxd.Event;
import h2d.Flow;
import h2d.Object;
import ui.domkit.element.ShadowedTextComp;
import ui.domkit.element.TextButtonComp;

class ConfirmComp extends Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC = 
		<confirm-comp layout="vertical" vspacing="15">
			<shadowed-text( message ) scale="1.5" />
			<text-button( "ok", onOkBtn ) />
			${
				if( onCancelBtn != null ) 
					<text-button( "cancel", onCancelBtn ) />
			}
		</confirm-comp>
	// @formatter:on
	public function new( message : String, onOkBtn : Event -> Void, ?onCancelBtn : Event -> Void, ?parent : Object ) {
		super( parent );
		initComponent();
	}
}

class ConfirmDialog extends FocusMenu {

	public function new( message : String, onOkBtn : Event -> Void, ?onCancelBtn : Event -> Void, ?parent : Object ) {
		super( parent );
		centrizeContent();

		new ConfirmComp( message,
			( e ) -> {
				onOkBtn( e );
				destroy();
			},
			onCancelBtn == null ? onCancelBtn : ( e ) -> {
				onCancelBtn( e );
				destroy();
			},
			contentFlow );
	}

	override function backgroundOnClick( e ) {}
}
