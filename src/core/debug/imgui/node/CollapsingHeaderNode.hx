package core.debug.imgui.node;

import core.debug.imgui.node.intermediate.TextNode;
import imgui.ImGui;

class CollapsingHeaderNode extends TextNode {

	override function exec() {
		if ( ImGui.collapsingHeader( text ) ) {
			ImGui.indent();
			super.exec();
		}
	}
}
