package ui.domkit;

import util.Assets;
import h2d.Font;
import h2d.Object;
import h2d.RenderContext;
import h2d.domkit.Style;
import h2d.filter.Shader;
import shader.CornersRounder;
import ui.domkit.element.ShadowedTextComp;

@:uiComp( "textLabel" )
class TextLabelComp extends h2d.Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC =
		<textLabel id="labelThis">
			// <shadowed-text(text, font) public id="shadowed_text" />
			<text text='$text' public id="shadowed_text" />
		</textLabel>;

	// @formatter:on
	public var label( get, set ) : String;
	public var font( get, set ) : Font;

	function get_label()
		return shadowed_text.text;

	function set_label( s ) {
		shadowed_text.text = s;
		return s;
	}

	function set_font( s ) {
		shadowed_text.font = s;
		return s;
	}

	function get_font()
		return shadowed_text.font;

	public var cornersRounder : CornersRounder;

	public function new( text : String, ?font : Font, ?style : Style, ?parent : Object ) {
		super( parent );
		initComponent();
		font = font == null ? Assets.fontPixel : font;
		this.font = font;
		label = text;

		style = style == null ? new h2d.domkit.Style() : style;
		style.load( hxd.Res.domkit.textlabel );
		style.addObject( this );

		cornersRounder = new CornersRounder();
		filter = new Shader( cornersRounder );
	}

	override function sync( ctx : RenderContext ) {
		// if( forceDecrHeight != null )
		// 	@:privateAccess
		// 	shadowed_text.calcYMin = forceDecrHeight;

		super.sync( ctx );
	}
}
