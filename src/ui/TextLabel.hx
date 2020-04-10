package ui;

import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("textLabel")
class  TextLabel extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<textLabel class="textLabel" public id="textLabel">
  			<flow class="containerFlow" >
    			<flow public id="borderFlow">
    		  		<text public id="labelTxt" />
   				</flow>
 			</flow>
		</textLabel>
	
	public var label(get, set):String;
	public var font(default, set):Font;
	public var disposed:Bool = false;
	
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

	public function new(align:h2d.Flow.FlowAlign, text:String, font:Font, ?scale:Float = 1, ?baseWidth:Int, ?parent:Object) {
		super(parent == null ? Boot.inst.s2d : parent);
		initComponent();

		// width = baseWidth;
		textLabel.textLabel.minWidth = baseWidth;

		// TODO: Make rounded corners border
		// textLabel.borderFlow.backgroundTile = h2d.Tile.fromColor(0xFFFFFF, 500, 32);
		// textLabel.borderFlow.minWidth = textLabel.containerFlow.minWidth;
		// textLabel.borderFlow.blendMode = textLabel.textLabel.blendMode= Multiply;
		this.font = font;	
		label = text;
		labelTxt.lineSpacing = 0;
		var style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.textlabel);
		style.addObject(textLabel);

		super.scale(scale);
	}

	public function dispose() {
		textLabel.remove();
		this.remove();
		disposed = true;
	}
}
