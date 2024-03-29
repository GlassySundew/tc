package en.items;

import cherry.soup.EventSignal.EventSignal1;
import game.client.GameClient;
import h2d.Object;

using en.util.EntityUtil;

class Blueprint extends Item {

	// public var onStructurePlace : EventSignal1<StructTile> = new EventSignal1();
	// public var onStructTileMove : EventSignal1<StructTile> = new EventSignal1();

	public var blueprintScheme : Data.BlueprintKind;

	public var ghostStructure : StructureGhost;

	public function new( cdbEntry : Data.ItemKind ) {
		super( cdbEntry );

		if ( cdbEntry != null && this != null ) {
			for ( i in Data.blueprint.all ) {
				if ( i.itemId == cdbEntry ) {
					blueprintScheme = i.id;
				}
			}
		}

		// onStructTileMove.add( ( tile ) -> {
		// 	if ( ghostStructure != null ) {
		// 		ghostStructure.setFeetPos( tile.x, tile.z, ghostStructure.model.footZ );
		// 		ghostStructure.offsetFootByCenter();
		// 		ghostStructure.offsetFootByTile();
		// 	}
		// } );
		// onStructurePlace.add( ( tile ) -> {
		// 	if ( ghostStructure.canBePlaced ) {
		// 		amount--;
		// 		var ent = Structure.fromCdbEntry( Std.int( tile.x ), Std.int( tile.z ), Data.blueprint.get( blueprintScheme ).structureId );
		// 		// GameClient.inst.applyTmxObjOnEnt(ent);
		// 		if ( ghostStructure.model.flippedX ) ent.flipX();
		// 		ent.offsetFootByTile();
		// 	}
		// } );

		// onPlayerHold.add(() -> {
		// 	GameClient.inst.showStrTiles();
		// 	ghostStructure = new StructureGhost();
		// 	ghostStructure.model.cdb.val = Data.blueprint.get( blueprintScheme ).structureId;
		// } );

		// onPlayerRemove.add(() -> {
		// 	GameClient.inst.hideStrTiles();
		// 	ghostStructure.destroy();
		// } );
	}
}
