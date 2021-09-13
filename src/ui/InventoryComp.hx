package ui;

import h2d.Bitmap;
import ui.InventoryGrid.CellGrid;
import ui.WindowComp.WindowCompI;
import ui.TextLabelComp;
import h2d.Flow;

@:uiComp("inventoryComp")
class InventoryComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	var cellTile : h2d.Tile;

	static var SRC = 
		<inventoryComp >
			<window(backgroundTile, bl, bt, br, bb) class="window" public id="window" layout="vertical">
					
					<flow class="slots_holder" layout="vertical" >
						${ 
							if ( invGrid != null ) {
								for ( y in 0...(removeLastRow ? invGrid.height - 1 : invGrid.height) ) {
									<flow id="hor_holder[]">
									for ( x in 0...invGrid.width ) {
										<bitmap src={cellTile} class="inv_cell" id="inv_cells[]"/>
									}
									</flow>
								}
							}
						}
					</flow>

			</window>
		</inventoryComp>;

	public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?removeLastRow:Bool = false, ?invGrid : CellGrid, ?parent ) {
		super(parent);
		cellTile = new HSprite(Assets.ui, "inventory_cell").tile;
		
		initComponent();

		for ( yI => y in invGrid.grid) {
			for ( xI => x in y ) {
				try {
					x.inter.onPushEvent.add((e) -> {
						window.bringOnTopOfALL();
					});
					
					inv_cells[yI * invGrid.width + xI].addChild(x);
				} catch ( e : Dynamic ) {}
			}
		}

        window.makeCloseButton();
        window.makeDragable();

		window.style.load(hxd.Res.domkit.inventory);
		window.style.addObject(this);

	}
}