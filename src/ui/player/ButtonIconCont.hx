package ui.player;

import h2d.Tile;
@:noClosure

class ButtonIconCont extends h2d.Flow implements h2d.domkit.Object {
	 static var SRC =  <button-icon-cont>
		 	<bitmap src={tile} public id="icon">
				<flow public id="activateTextFlow">
					<text text="E" public id="activateText" />
					</flow>
				</bitmap>
		</button-icon-cont>;
	public function new(?tile:Tile, ?parent) {
		super(parent);
		initComponent();
	}
}