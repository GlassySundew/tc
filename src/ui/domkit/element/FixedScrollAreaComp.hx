package ui.domkit.element;

import ui.core.FixedScrollArea;
import h2d.Object;
import h2d.col.Bounds;

@:uiComp( "fixed-scroll-area" )
class FixedScrollAreaComp extends FixedScrollArea implements h2d.domkit.Object {

	// @formatter:off
	// static var SRC =
	// 	<fixed-scroll-area>
	// 	</fixed-scroll-area>

	// @formatter:on

	public function new(
		?width : Int = 0,
		?height : Int = 0,
		?fillWidth = false,
		?fillHeight = false,
		?scrollStep : Int = 16,
		?bounds : Bounds,
		?parent : h2d.Object
	) {
		super(
			width,
			height,
			fillWidth,
			fillHeight,
			scrollStep,
			bounds,
			parent
		);
		initComponent();
	}
}
