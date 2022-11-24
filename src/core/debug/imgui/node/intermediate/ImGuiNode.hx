package core.debug.imgui.node.intermediate;

import cherry.soup.EventSignal.EventSignal1;

class ImGuiNode extends NodeBase<ImGuiNode> {

	public final onChild = new EventSignal1<ImGuiNode>();

	public function exec() {
		for ( child in children ) {
			child.exec();
			onChild.dispatch( child );
		}
	}
}
