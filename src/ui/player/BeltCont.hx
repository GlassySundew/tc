package ui.player;

import shader.CornersRounder;
import h2d.Tile;
import h2d.Object;
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
			<flow class="backgroundFlow" public id="backgroundFlow" />
			<flow class="itemContainer" public id="itemContainer" />
			<flow class="hotkeyFlow">
				<text class="beltSlotNumber" public id="beltSlotNumber" text={Std.string(slotNumber)} font={font} />
			</flow>
		</beltCont>;
	public function new(?font : Font, ?slotNumber : Int, ?parent) {
		super(parent);
		initComponent();

		ShadowedText.addTextOutlineTo(beltSlotNumber);
		
		var shader = new CornersRounder(6);
		backgroundFlow.filter = new Shader(shader);
	}
}
