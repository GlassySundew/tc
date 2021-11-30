package ui.domkit;

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
		<textLabel public id="textLabel">
		    <flow class="backgroundHolder" public id="backgroundHolder" position="absolute" />
		    <flow class="containerFlow" public id="containerFlow">
		        <text class="textLabel" public id="labelTxt" />
		    </flow>
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

	var outline : Outline;
	public var backgroundColor(default, set) : Int;

	function set_backgroundColor(v : Int) {
		var alpha = Color.getAlpha(v);
		outline.color = v;

		backgroundHolder.backgroundTile = h2d.Tile.fromColor(v, 1, 1, alpha / 255);
		return v;
	}
	
	public function new(text:String, ?font:Font, ?parent:Object) {
		super(parent);
		initComponent();
		font = font == null ? Assets.fontPixel : font;
		this.font = font;
		label = text;
		
		ShadowedText.addTextOutlineTo(labelTxt);

		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.textlabel);

		style.addObject(textLabel);
		
		outline = new Outline(1);
		backgroundHolder.filter = outline;

		backgroundColor = Color.rgbaToInt({ r : 0, g : 0, b : 0, a : 80 });
	}
	
override function sync(ctx:RenderContext) {
	backgroundHolder.minWidth = containerFlow.outerWidth;
	backgroundHolder.minHeight = containerFlow.outerHeight;

	backgroundHolder.x = containerFlow.x;
	backgroundHolder.y = containerFlow.y;
	
	super.sync(ctx);
}
	public function dispose() {
		textLabel.remove();
		this.remove();
	}
}
