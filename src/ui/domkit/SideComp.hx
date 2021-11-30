package ui.domkit;

import h2d.Flow.FlowAlign;

class SideComp extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = 
		<side-comp content-halign='${hor}' content-valign='${vert}' > </side-comp>;
	 
	public function new(vert:FlowAlign, hor:FlowAlign, ?parent) {
		super(parent);
		initComponent();

	}
}
