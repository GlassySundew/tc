package en.util;

import en.util.item.IInventory;
import ui.Window;
import ui.core.InventoryGrid;
import en.util.item.InventoryCell;
import haxe.Json;

class ItemUtil {

	public static var inventories : Array<IInventory> = [];

	/**
		{
			"items" : [
				{ "id" : "axe", "amount" : "1" },
				{ "id" : "iron", "amount" : "2" }
			]
		}
	**/
	public static function resolveJsonItemStorage( json : String, outputInventory : InventoryGrid ) {
		var data = Json.parse( json );
		for ( item in cast( data.items, Array<Dynamic> ) ) {
			var cell = new InventoryCell( Cursor, null );
			cell.item = Item.fromCdbEntry(
				Data.item.resolve( item.id ).id,
				null,
				item.amount
			);
			outputInventory.giveItem( cell );
		}
	}

	public static function swapItems( cell1 : InventoryCell, cell2 : InventoryCell ) {
		var temp = cell1.item;
		cell1.item = cell2.item;
		cell2.item = temp;
	}

	public static function enableWindowCellGridInteractivity( val : Bool ) {
		for ( inv in inventories ) {
			if ( val ) inv.cellFlowGrid.enableGrid();
			else inv.cellFlowGrid.disableGrid();
		}
	}
}
