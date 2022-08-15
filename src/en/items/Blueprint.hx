package en.items;

import game.client.GameClient;
import game.client.level.Level.StructTile;
import cherry.soup.EventSignal.EventSignal1;
import h2d.Object;

class Blueprint extends Item {

	public var onStructurePlace : EventSignal1<StructTile> = new EventSignal1();
	public var onStructTileMove : EventSignal1<StructTile> = new EventSignal1();

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

		onStructTileMove.add( ( tile ) -> {
			if ( ghostStructure != null ) {
				ghostStructure.setFeetPos( tile.x, tile.z );
				ghostStructure.offsetFootByCenter();
				ghostStructure.offsetFootByTile();
			}
		} );
		onStructurePlace.add( ( tile ) -> {
			if ( ghostStructure.canBePlaced ) {
				amount--;
				var ent = Structure.fromCdbEntry( Std.int( tile.x ), Std.int( tile.z ), Data.blueprint.get( blueprintScheme ).structureId );
				// GameClient.inst.applyTmxObjOnEnt(ent);
				if ( ghostStructure.flippedX ) ent.flipX();
				ent.offsetFootByTile();
			}
		} );

		onPlayerHold.add(() -> {
			GameClient.inst.showStrTiles();
			ghostStructure = new StructureGhost( Data.blueprint.get( blueprintScheme ).structureId );
		} );

		onPlayerRemove.add(() -> {
			GameClient.inst.hideStrTiles();
			ghostStructure.destroy();
		} );
	}
}
