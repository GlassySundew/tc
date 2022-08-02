package ui.domkit.element;

import ui.core.TextButton;
import hxd.Event;
import h2d.domkit.Object;

@:uiComp( "text-button" )
class TextButtonComp extends TextButton implements Object {

	public function new(
		title : String,
		?action : Event -> Void,
		?colorDef : Int = 0xffffff,
		?colorPressed : Int = 0x676767,
		?prefix : String = "> ",
		?parent : h2d.Object
	) {
		super( title, prefix, action, colorDef, colorPressed, parent );
		initComponent();
	}
}
