package ui;

import h2d.col.Bounds;
import h2d.Tile;
import h2d.RenderContext;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("textLabel")
class TextLabel extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<textLabel public id="textLabel">
			<flow class="containerFlow" public id="containerFlow" >
				// <flow public id="borderFlow">
			  		<text class="textLabel" public id="labelTxt" />
				// </flow>
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

	public function new(text:String, font:Font, ?parent:Object) {
		super(parent);
		initComponent();
		// width = baseWidth;
		// textLabel.textLabel.minWidth = baseWidth;
		// TODO: Make rounded corners border
		// textLabel.borderFlow.backgroundTile = h2d.Tile.fromColor(0xFFFFFF, 500, 32);
		// textLabel.borderFlow.minWidth = textLabel.containerFlow.minWidth;
		// textLabel.borderFlow.blendMode = textLabel.textLabel.blendMode= Multiply;
		this.font = font;
		label = text;
		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.textlabel);
		style.addObject(textLabel);
		// trace(this.filter);
		// this.filter = null;
		// this.font.resizeTo(16);
	}
	public function center() {
		paddingLeft = -innerWidth >> 1;
		paddingTop = -innerHeight >> 1;
	}

	public function dispose() {
		textLabel.remove();
		this.remove();
	}
}
