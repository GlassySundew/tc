package core.debug.imgui.node;

import imgui.ImGui;
import core.debug.imgui.node.intermediate.TextNode;

class LabelTextNode extends TextNode {

	override function exec() {
		ImGui.text( text );
		super.exec();
	}
}
