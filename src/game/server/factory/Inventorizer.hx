package game.server.factory;

import en.Entity;
import en.model.InventoryModel;
import ui.core.InventoryGrid;


@:allow( game.server.factory.EntityFactory )
class Inventorizer {

	public static inline function inventorize( e : Entity ) {
		var inventoryModel : InventoryModel = Reflect.field( e, "inventoryModel" );
		if ( inventoryModel == null ) return;

		var cdb = e.model.cdb;
		var cdbInv = Data.inventory.all.filter( ( inv ) -> inv.entityId == cdb )[0];
		if ( cdbInv == null ) return;

		inventoryModel.inventory = new InventoryGrid( cdbInv.width, cdbInv.height, Chest, e );
	}
}
