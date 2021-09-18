package ui;

import ui.domkit.ScrollbarComp;
import h2d.Object;

class Scrollbar extends NinesliceWindow {
	public function new( ?parent : Null<Object> ) {
		super("craft-caret", ( tile, bl, bt, br, bb, parent ) -> {
			new ScrollbarComp(tile, bl, bt, br, bb, parent);
		}, parent);

        windowComp.window.windowLabel.remove();
        


	}
}
