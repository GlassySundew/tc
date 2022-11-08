package ui.player;

import en.Item.ItemPresense;
import en.player.Player;
import en.util.ItemUtil;
import en.util.item.IInventory;
import en.util.item.InventoryCell;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.domkit.Style;
import hxd.Event;
import hxd.Key;
import ui.core.InventoryGrid;
import utils.Assets;

class Belt extends Flow implements IInventory {

	var style : Style;

	public var beltSlots : Array<BeltCont> = [];

	public var selectedCell : BeltCont;
	public var selectedCellNumber : Int = 0;

	public var cellFlowGrid : InventoryCellFlowGrid;
	public var inventory : InventoryGrid;

	public var isVisible( get, never ) : Bool;

	inline function get_isVisible() : Bool return visible;

	public var type( get, never ) : en.Item.ItemPresense;

	function get_type() return ItemPresense.PlayerBelt;

	public function new( cellGrid : Array<InventoryCell>, ?parent : h2d.Object ) {
		super( parent );

		inventory = new InventoryGrid( 1, cellGrid.length, type, [cellGrid], Player.inst );
		cellFlowGrid = new InventoryCellFlowGrid( inventory, 0, 0 );

		style = new h2d.domkit.Style();
		style.load( hxd.Res.domkit.belt );

		function onCellClicked( i : Int, event : Event ) {
			switch event.button {
				case 0:
					if ( !Player.inst.pui.inventory.win.visible ) {
						Player.inst.pui.belt.selectCell( i );
					}
					if ( Key.isDown( Key.SHIFT ) ) {}
				default:
			}
		}

		for ( row in cellFlowGrid.flowGrid )
			for ( i => cellFlow in row ) {
				var cell = cellFlow.cell;
				cellFlow.inter.onClickEvent.add( onCellClicked.bind( i ), 1 );
				var beltCont = new BeltCont( Assets.fontPixel, i + 1, this );
				beltSlots.push( beltCont );
				style.addObject( beltCont );
				beltCont.addChild( cellFlow );
				beltCont.getProperties( cellFlow ).isAbsolute = true;

				cellFlow.inter.width = beltSlots[0].innerWidth;
				cellFlow.minWidth = beltSlots[0].innerWidth;
				cellFlow.inter.height = beltSlots[0].innerHeight;
				cellFlow.minHeight = beltSlots[0].innerHeight;
			}

		deselectCells();
		ItemUtil.inventories.push( this );
	}

	public function selectCell( number : Int = 1 ) {
		deselectCells();

		if ( Player.inst.holdItem.item == null || Player.inst.holdItem.item.itemPresense != Cursor ) {
			selectedCellNumber = number;
			var cell = beltSlots[number];

			cell.dom.active = true;
			cell.backgroundFlow.dom.active = true;

			Player.inst.holdItem.item = Player.inst.pui.beltLayer[number].item;

			style.addObject( cell );
			cell.onSelect();
		}
	}

	public function deselectCells() {
		for ( cell in beltSlots ) {
			cell.dom.active = false;
			cell.backgroundFlow.dom.active = false;

			style.addObject( cell );
		}
	}

	override function sync( ctx : RenderContext ) {
		super.sync( ctx );
	}

	override function onRemove() {
		super.onRemove();
		ItemUtil.inventories.remove( this );
		for ( i in beltSlots ) {
			i.remove();
			style.removeObject( i );
		}
	}
}
