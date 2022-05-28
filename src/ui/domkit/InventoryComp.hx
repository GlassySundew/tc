package ui.domkit;

import haxe.CallStack;
import ui.domkit.WindowComp.WindowCompI;
import h2d.Bitmap;
import ui.InventoryGrid.UICellGrid;
import ui.domkit.TextLabelComp;
import h2d.Flow;

@:uiComp("inventoryComp")
class InventoryComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	var cellTile : h2d.Tile;

	static var SRC = 
		<inventoryComp >
			<window(backgroundTile, bl, bt, br, bb) class="window" public id="window" layout="vertical">
					<flow class="slots_holder" layout="vertical" >
						${ if ( cellGrid != null ) {
							for ( y in 0...getGridHeight() ) {
								<flow class="hor_holder">
									for ( x in 0...cellGrid.inventoryGrid.width ) {
										<flow 
											background={{tile : cellTile, borderB : 1, borderT : 1,borderR : 1, borderL : 1}} 
											class="inv_cell"
											public id="inv_cells[]"
											min-width={cellGrid.cellWidth}
											min-height={cellGrid.cellHeight}
										/>
									}
								</flow>
							}
						} }
					</flow>
			</window>
		</inventoryComp>

	public var cellGrid : UICellGrid;
	public var removeLastRow:Bool = false;
	
		// ?removeLastRow:Bool = false,
		// ?cellGrid : CellGrid, 
		/**
			@param rest cellGrid : UICellGrid, removeLastRow : Bool
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

		if(cellGrid != null)
			for ( yi in 0...getGridHeight()) {
				for ( xi => x in cellGrid.flowGrid[yi] ) {
					try {
						inv_cells[yi * cellGrid.inventoryGrid.width + xi].addChild(x);
					} catch ( e ) {
						for( i in CallStack.callStack()) {
							trace(i);
						}
					}
				}
			}
	}

	function getGridHeight() : Int {
		return (removeLastRow ? cellGrid.inventoryGrid.height - 1 : cellGrid.inventoryGrid.height);
	}
}