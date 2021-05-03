package ui.player;

import h2d.RenderContext;
import h2d.filter.Shader;
import h2d.filter.Outline;
import h3d.Vector;
import cherry.plugins.generic.shaders.OutlineShader;
import h2d.Font;

@:uiComp("beltCont")
class BeltCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<beltCont>
			<flow class="beltSlot" public id="beltSlot">
				<flow class="backgroundHolder" public id="backgroundHolder" />
				<flow class="itemContainer" public id="itemContainer" />
				<flow class="hotkeyContainer">
				<text
					class="beltSlotNumber"
					public
					id="beltSlotNumber"
					text={Std.string(slotNumber)}
					font={font}
				/>
				</flow>
			</flow>
		</beltCont>;

	var outline : Outline;
	public var backgroundColor(default, set) : Int;

	function set_backgroundColor(v : Int) {
		outline.color = v;
		backgroundHolder.backgroundTile = h2d.Tile.fromColor(v, 1, 1, .58);
		return v;
	}

	public function new(?font : Font, ?slotNumber : Int, ?parent) {
		super(parent);
		initComponent();
		outline = new Outline(2);
		backgroundHolder.filter = outline;
	}
}
