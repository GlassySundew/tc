package core.debug.imgui;

import imgui.ImGuiDrawable;
import imgui.ImGuiMacro.wref;
import core.debug.imgui.node.intermediate.ImGuiNode;
import game.client.GameClient;
import imgui.ImGuiDrawable.ImGuiDrawableBuffers;
import h2d.Interactive;
import hxd.Key;
import utils.Const;
import dn.Process;
import imgui.ImGui;
import i.IDestroyable;

class ImGuiDebug extends Process implements IDestroyable {

	var drawable : ImGuiDrawable;
	var rootNode : ImGuiNode;

	public function new( parent : Process ) {
		super( parent );
	}

	override function update() {
		super.update();
		drawable.update( tmod );

		ImGui.pushStyleVar( WindowRounding, 3.0 );
		ImGui.pushStyleVar( FrameRounding, 2.0 );

		ImGui.newFrame();
		rootNode.exec();
		ImGui.showDemoWindow();

		ImGui.render();
	}

	override function onResize() {
		super.onResize();
		ImGui.setDisplaySize( Boot.inst.s2d.width, Boot.inst.s2d.height );
	}
}
