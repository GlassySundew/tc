package core.debug.imgui.node;

import game.client.debug.ImGuiGameClientDebug.FovAccessor;
import core.debug.imgui.node.intermediate.ImGuiNode;
import imgui.ImGuiMacro.wref;
import imgui.ImGui;

class DragDoubleNode extends ImGuiNode {

	var label : String;
	var v_speed : Float;
	var v_min : Float;
	var v_max : Float;
	var v : Accessor<Float>;

	public function new(
		label : String,
		v : Accessor<Float>,
		v_speed : Float = 1.0,
		v_min : Float = 0.0,
		v_max : Float = 10.0,
		parent : ImGuiNode
	) {
		this.label = label;
		this.v = v;
		this.v_speed = v_speed;
		this.v_min = v_min;
		this.v_max = v_max;

		super( parent );
	}

	override function exec() {
		imgui.ImGuiMacro.wref(
			ImGui.dragDouble(
				label,
				_,
				v_speed,
				v_min,
				v_max
			),
			v.val
		);
		super.exec();
	}
}
