package ui.dialog;

import h2d.Object;
import hxd.Event;
import cherry.soup.EventSignal.EventSignal1;
import ui.dialog.SaveManager.Mode;
import dn.Process;

class Dialog extends FocusMenu {
	var activateEvent : EventSignal1<Event>;

	public function new( mode : Mode, saveMan : SaveManager, ?parent : Object, ?parentProcess : Process ) {
		super( parent, parentProcess );
		this.activateEvent = new EventSignal1<Event>();

		this.activateEvent.add( ( e ) -> {
			refreshSaves();
			if ( saveMan != null && saveMan.h2dObject.getScene() != null ) saveMan.refreshEntries();
		}, -1 );
	}

	override function update() {
		super.update();
		// h2dObject.x = hxd.Math.clamp( x, 0, wScaled - getSize().width - 1 );
		// h2dObject.y = hxd.Math.clamp( y, 0, hScaled - getSize().height - 1 );
	}
}
