package ui.domkit.element;

import h2d.filter.Shader;
import shader.CornersRounder;

@:uiComp( "button-flow" )
class ButtonFlowComp extends h2d.Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC =
		<button-flow>
			<shadowed-text valign="middle" id="labelTxt" />
		</button-flow>

	// @formatter:on
	@:p public var label( get, set ) : String;

	function get_label() return labelTxt.text;

	function set_label( s ) {
		labelTxt.text = s;
		return s;
	}

	public function new( ?parent ) {
		super( parent );
		initComponent();
		enableInteractive = true;
		interactive.onClick = function ( _ ) onClick();
		interactive.onOver = function ( _ ) {
			dom.hover = true;
		};
		interactive.onPush = function ( _ ) {
			dom.active = true;
		};
		interactive.onRelease = function ( _ ) {
			dom.active = false;
		};
		interactive.onOut = function ( _ ) {
			dom.hover = false;
		};
		interactive.cursor = Button;

		filter = new Shader( new CornersRounder( 4 ) );
	}

	public dynamic function onClick() {}
}
