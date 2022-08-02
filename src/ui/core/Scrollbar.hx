package ui.core;

import ui.domkit.ScrollbarComp;
import h2d.Object;

class Scrollbar extends NinesliceWindow {
	public function new( ?parent : Null<Object> ) {
		super("craft-caret", ScrollbarComp, parent);

		windowComp.window.windowLabel.remove();
	}
}
