package ui.domkit;

import haxe.CallStack;
import ui.domkit.WindowComp.WindowCompI;
import h2d.Bitmap;
import ui.InventoryGrid.CellGrid;
import ui.domkit.TextLabelComp;
import h2d.Flow;

@:uiComp("inventoryComp")
class InventoryComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	var cellTile : h2d.Tile;

	static var SRC = 
		<inventoryComp >
			<window(backgroundTile, bl, bt, br, bb) class="window" public id="window" layout="vertical">
					<flow class="slots_holder" layout="vertical" >
						${ 
							if ( cellGrid != null ) {
								for ( y in 0...(removeLastRow ? cellGrid.height - 1 : cellGrid.height) ) {
									<flow class="hor_holder">
									for ( x in 0...cellGrid.width ) {
										<bitmap src={cellTile} class="inv_cell" public id="inv_cells[]">
											<flow public id="item_holder[]" class="item_holder" position="absolute" />
										</bitmap>
									}
									</flow>
								}
							}
						}
					</flow>
			</window>
		</inventoryComp>;

	public var cellGrid:CellGrid;
	public var removeLastRow:Bool = false;
	
		// ?removeLastRow:Bool = false,
		// ?cellGrid : CellGrid, 
		/**
			@param rest cellGrid : CellGrid, removeLastRow : Bool
		**/
	public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : h2d.Object, ...rest : Dynamic ) {
		super(parent);
		
		cellGrid = rest[0];
		removeLastRow = rest[1];

		cellTile = new HSprite(Assets.ui, "inventory_cell").tile;
		
		initComponent();

		window.makeCloseButton();
		window.makeDragable();

		window.style.load(hxd.Res.domkit.inventory);
	}

	override function reflow() {

		if(cellGrid != null)
			for ( yI => y in cellGrid.grid) {
				for ( xI => x in y ) {
					try {
						x.inter.onPushEvent.add((e) -> {
							window.bringOnTopOfALL();
						});
						
						item_holder[yI * cellGrid.width + xI].addChild(x);
						item_holder[yI * cellGrid.width + xI].x = -Std.int((x.inter.width - inv_cells[yI * cellGrid.width + xI].tile.width ) / 2);
						item_holder[yI * cellGrid.width + xI].y = -Std.int((x.inter.height - inv_cells[yI * cellGrid.height + xI].tile.height ) / 2);
					} catch ( e : Dynamic ) {}
				}
			}

		super.reflow();
	}
}