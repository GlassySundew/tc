package ui.player;

import h2d.Tile;
@:noClosure
@:uiComp("cont")
class ButtonIconCont extends h2d.Flow implements h2d.domkit.Object {
	 static var SRC =  <cont>
		 	<bitmap src={tile} public id="icon">
				<flow public id="activateTextFlow">
					<text text="E" public id="activateText" />
					</flow>
				</bitmap>
		</cont>;
	public function new(?tile:Tile, ?parent) {
		super(parent);
		initComponent();
	}
}