package core.debug.imgui.node;

import core.debug.imgui.node.intermediate.TextNode;
import imgui.ImGui;

class WindowNode extends TextNode {

	override function exec() {
		ImGui.begin( text );
		super.exec();
		ImGui.end();
	}
}
