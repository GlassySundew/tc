package ui.domkit;

import h2d.Tile;

class ButtonIconComp extends h2d.Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC =
		<button-icon-comp>
			<bitmap src={tile} public id="icon">
				<flow public id="activateTextFlow">
					<text text="E" public id="activateText" />
				</flow>
			</bitmap>
		</button-icon-comp>
		
	// @formatter:on
	public function new( ?tile : Tile, ?parent ) {
		super( parent );
		initComponent();
	}
}
