package core.debug.imgui.controller;

import imgui.ImGui;
import core.debug.imgui.node.intermediate.ImGuiNode;

class SameLineController {

	public static function attach( node : ImGuiNode ) {
		node.onChild.add( ( e ) -> ImGui.sameLine() );
	}
}
