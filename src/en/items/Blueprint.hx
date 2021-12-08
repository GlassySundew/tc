package en.items;

import Level.StructTile;
import cherry.soup.EventSignal.EventSignal1;
import h2d.Object;

class Blueprint extends Item {
	public var onStructurePlace : EventSignal1<StructTile> = new EventSignal1();
	public var onStructTileMove : EventSignal1<StructTile> = new EventSignal1();

	public var blueprintScheme : Data.BlueprintsKind;

	public var ghostStructure : StructureGhost;

	public function new( cdbEntry : Data.ItemsKind, ?parent : Object ) {
		super(cdbEntry, parent);

		if ( cdbEntry != null && this != null ) {
			for ( i in Data.blueprints.all ) {
				if ( i.itemId == cdbEntry ) {
					blueprintScheme = i.id;
				}
			}
		}

		onStructTileMove.add(( tile ) -> {
			if ( ghostStructure != null ) {
				ghostStructure.setFeetPos(tile.x, tile.z);
				ghostStructure.offsetFootByCenter();
				ghostStructure.offsetFootByTile();
			}
		});
		onStructurePlace.add(( tile ) -> {
			if ( ghostStructure.canBePlaced ) {
				amount--;
				var ent = Structure.fromCdbEntry(Std.int(tile.x), Std.int(tile.z), Data.blueprints.get(blueprintScheme).structureId);
				Level.inst.game.applyTmxObjOnEnt(ent);
				if ( ghostStructure.flippedX ) ent.flipX();
				ent.offsetFootByTile();
			}
		});

		onPlayerHold.add(() -> {
			#if !headless
			Level.inst.game.showStrTiles();
			ghostStructure = new StructureGhost(Data.blueprints.get(blueprintScheme).structureId);
			#end
		});

		onPlayerRemove.add(() -> {
			#if !headless
			Level.inst.game.hideStrTiles();
			ghostStructure.destroy();
			#end
		});
	}
}
