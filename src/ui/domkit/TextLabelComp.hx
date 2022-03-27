package ui.domkit;

import shader.CornersRounder;
import hxd.Res;
import h2d.filter.Shader;
import h2d.filter.Outline;
import h2d.col.Bounds;
import h2d.Tile;
import h2d.RenderContext;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("textLabel")
class TextLabelComp extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<textLabel id="labelThis">
		    <text class="textLabel" public id="labelTxt" smooth="false"/>
		</textLabel>;

	public var label(get, set):String;
	public var font(get, set):Font;

	function get_label()	
		return labelTxt.text;

	function set_label(s) {
		labelTxt.text = s;
		return s;
	}

	function set_font(s) {
		labelTxt.font = s;
		return s;
	}

	function get_font()
		return labelTxt.font;

	public var cornersRounder : CornersRounder;
	public var forceDecrHeight : Null<Int>;
	public function new(text:String, ?font:Font, ?style : Style, ?parent:Object) {
		super(parent);
		initComponent();
		font = font == null ? Assets.fontPixel : font;
		this.font = font;
		label = text;
		
		ShadowedText.addTextOutlineTo(labelTxt);

		style = style == null ? new h2d.domkit.Style() : style;
		style.load(hxd.Res.domkit.textlabel);
		style.addObject(this);

		cornersRounder = new CornersRounder();
		filter = new Shader(cornersRounder);
	}
	
	override function sync(ctx:RenderContext) {
		if( forceDecrHeight != null )
			@:privateAccess
			labelTxt.calcYMin = forceDecrHeight;
		
		super.sync(ctx);
	}
}
