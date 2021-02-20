package en.items;

import Level.StructTile;
import ui.s3d.EventInteractive;
import cherry.soup.EventSignal.EventSignal1;
import cherry.soup.EventSignal.EventSignal0;
import h2d.Object;

class Blueprint extends Item {
	public var onStructurePlace : EventSignal1<StructTile> = new EventSignal1();
	public var onStructTileMove : EventSignal1<StructTile> = new EventSignal1();

	public var blueprintScheme : BlueprintsKind;

	public var ghostStructure : StructureGhost;

	public function new(cdbEntry : Data.ItemsKind, ?parent : Object) {
		super(cdbEntry, parent);

		if ( cdbEntry != null && this != null ) {
			for (i in Data.blueprints.all) {
				if ( i.itemId == cdbEntry ) {
					blueprintScheme = i.id;
				}
			}
		}
		
		onStructTileMove.add((tile) -> {
			if ( ghostStructure != null ) {
				ghostStructure.setFeetPos(tile.x,
					tile.z + (StructTile.polyPrim != null ? StructTile.polyPrim.getBounds().zSize / 2 - Level.inst.data.tileHeight : 0));
				ghostStructure.offsetFootByCenter();
			}
		});
		onStructurePlace.add((tile) -> {
			if ( ghostStructure.canBePlaced ) {
				amount--;
				var ent = Structure.fromCdbEntry(Std.int(tile.x),
					Std.int(tile.z + (StructTile.polyPrim != null ? StructTile.polyPrim.getBounds().zSize / 2 - Level.inst.data.tileHeight : 0)),
					Data.blueprints.get(blueprintScheme).structureId);
				Level.inst.game.applyTmxObjOnEnt(ent);
				if ( ghostStructure.flippedX ) ent.flipX();
			}
		});
		
		onPlayerHold.add(() -> {
			Level.inst.game.showStrTiles();
			ghostStructure = new StructureGhost(Data.blueprints.get(blueprintScheme).structureId);
		});

		onPlayerRemove.add(() -> {
			Level.inst.game.hideStrTiles();
			ghostStructure.destroy();
		});
	}
}
