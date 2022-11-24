package core.debug.imgui.node.intermediate;

abstract class TextNode extends ImGuiNode {

	var text : String;

	public function new( text : String, ?parent : ImGuiNode ) {
		this.text = text;
		super( parent );
	}
}
