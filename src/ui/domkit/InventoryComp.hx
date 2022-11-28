package ui.domkit;

import h2d.Flow;
import haxe.CallStack;
import ui.core.InventoryGrid.InventoryCellFlowGrid;
import ui.domkit.WindowComp.WindowCompI;
import util.Assets;
import dn.heaps.slib.HSprite;

@:uiComp( "inventoryComp" )
class InventoryComp extends WindowComp {

	var cellTile : h2d.Tile;

	static var SRC = //
		<inventoryComp >
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
		</inventoryComp>

	public var cellGrid : InventoryCellFlowGrid;
	public var removeLastRow : Bool = false;

	// ?removeLastRow:Bool = false,
	// ?cellGrid : CellGrid,

	/**
		@param rest cellGrid : InventoryCellFlowGrid, removeLastRow : Bool
	**/
	public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : h2d.Object, ... rest : Dynamic ) {
		super( backgroundTile, bl, bt, br, bb, parent );

		cellGrid = rest[0];
		removeLastRow = rest[1];

		cellTile = new HSprite( Assets.ui, "inventory_cell" ).tile;

		initComponent();

		window.makeCloseButton();
		window.makeDragable();

		window.style.load( hxd.Res.domkit.inventory );

		if ( cellGrid != null )
			for ( yi in 0...getGridHeight() ) {
				for ( xi => x in cellGrid.flowGrid[yi] ) {
					try {
						inv_cells[yi * cellGrid.inventoryGrid.width + xi].addChild( x );
					} catch( e ) {
						for ( i in CallStack.callStack() ) {
							trace( i );
						}
					}
				}
			}
	}

	function getGridHeight() : Int {
		return ( removeLastRow ? cellGrid.inventoryGrid.height - 1 : cellGrid.inventoryGrid.height );
	}
}
