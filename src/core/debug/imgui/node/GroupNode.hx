package core.debug.imgui.node;

import imgui.ImGui;
import core.debug.imgui.node.intermediate.ImGuiNode;

class GroupNode extends ImGuiNode {
    override function exec() {
        ImGui.beginGroup();
        super.exec();
        ImGui.end();
    }
}