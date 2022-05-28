package ui.domkit.element;

import h2d.Font;
import h2d.domkit.Object;

@:uiComp( "text-input" )
class TextInputComp extends ui.TextInput implements h2d.domkit.Object {

	@:p public var backgroundColorProp( default, set ) : Int;

	function set_backgroundColorProp( v : Int ) {
		return backgroundColorProp = backgroundColor = v;
	}

	@:p public var inputWidthProp( default, set ) : Int;

	function set_inputWidthProp( v : Int ) {
		return inputWidth = v;
	}

	public function new( ?font : Font, ?parent ) {
		super( font == null ? Assets.fontPixel : font, parent );
		initComponent();
	}
}
