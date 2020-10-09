package ui.player;

import h2d.Flow.FlowAlign;

@:uiComp("sideCont")
class SideCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <sideCont content-halign = '${hor}' content-valign = '${vert}'> </sideCont>;
	
	public function new(vert:FlowAlign, hor:FlowAlign, ?parent) {
		super(parent);
		initComponent();
	}
}
