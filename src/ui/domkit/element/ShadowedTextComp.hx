package ui.domkit.element;

import ui.core.ShadowedText;
import h2d.Font;
import h2d.Object;

@:uiComp( "shadowed-text" )
class ShadowedTextComp extends ShadowedText implements h2d.domkit.Object {

	public function new( ?text : String, ?font : Font, ?parent : h2d.Object ) {
		super( font, parent );
		initComponent();

		this.text = text;
	}
}
