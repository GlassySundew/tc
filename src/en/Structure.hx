package en;

import format.tmx.Data.TmxObject;
import h2d.Bitmap;
import h3d.mat.Texture;
import hxd.Res;

class Structure extends Interactive {
	public var cdbEntry : StructuresKind = null;

	public function new(x : Int, y : Int, ?tmxObject : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, y, tmxObject);
		this.cdbEntry = cdbEntry;
		
		#if !headless
		// Нажатие для того, чтобы сломать структуру
		interact.onPushEvent.add(event -> {
			if ( Game.inst.player.holdItem != null ) applyItem(Game.inst.player.holdItem);
		});
		interact.onOverEvent.add((_) -> activateInteractive());
		interact.onOutEvent.add((e : hxd.Event) -> {
			turnOffHighlight();
		});
		#end
		// CDB parsed entry corresponding to this structure instance
		if ( cdbEntry != null ) try {
			eregClass.match('$this'.toLowerCase());
			cdbEntry = Data.structures.resolve(eregClass.matched(1)).id;
		}
		catch( Dynamic ) {
			// or name of the picture
			try {
				cdbEntry = Data.structures.resolve(spr.groupName).id;
			}
			catch( Dynamic ) {}
		}

		// Setting parameters from cdb entry
		if ( cdbEntry != null ) {
			useRange = Data.structures.get(cdbEntry).use_range;

			health = Data.structures.get(cdbEntry).hp;
			#if !headless
			if ( Data.structures.get(cdbEntry).isoHeight != 0 && Data.structures.get(cdbEntry).isoWidth != 0 ) {
				mesh.isLong = true;
				mesh.isoWidth = Data.structures.get(cdbEntry).isoWidth;
				mesh.isoHeight = Data.structures.get(cdbEntry).isoHeight;
				mesh.renewDebugPts();
			}
			#end
		}
	}

	public function applyItem(item : Item) {
		emitDestroyItem(item);
		if ( Data.items.get(item.cdbEntry).can_hit ) {
			// Damaging the structure
			if ( health > Data.items.get(item.cdbEntry).damage ) {
				health -= Data.items.get(item.cdbEntry).damage;
			} else {
				dispose();
			}
		} else {
			item.structureUsingEvent.dispatch();
		}
	}

	public function emitDestroyItem(item : Item) {
		var hitPart = Res.hit_ico.toGpuParticlesClamped(mesh);
		hitPart.z = 15;

		var texture = new Texture(Std.int(item.spr.tile.width), Std.int(item.spr.tile.height), [Target]);

		var bmp = new Bitmap(item.spr.tile);
		bmp.x = item.spr.tile.width / 2;
		bmp.y = item.spr.tile.height / 2;
		bmp.drawTo(texture);

		@:privateAccess
		{
			hitPart.getGroup("main").texture = texture;
			hitPart.materials[0].mainPass.depth(false, Less);
			hitPart.getGroup("main").pshader.stopAt = 0.2;
			hitPart.getGroup("main").emitMode = FlatInversedDisc;
		}
		hitPart.scale(hitPart.getGroup("main").size);
		hitPart.getGroup("main").texture.filter = Nearest;

		hitPart.rotate(M.toRad(M.randRange(-13, 13)), 0, 0);

		hitPart.onEnd = () -> {
			hitPart.remove();
			hitPart = null;
		};
	}

	public static function fromCdbEntry(x : Int, y : Int, cdbEntry : StructuresKind, ?amount : Int = 1) : Structure {
		var structure : Structure = null;
		var entClasses = (CompileTime.getAllClasses(Structure));
		for (e in entClasses) {
			// if ( Data.structures.get(cdbEntry).cat != blueprint ) {
			if ( eregCompTimeClass.match('$e'.toLowerCase())
				&& eregCompTimeClass.matched(1) == Data.structures.get(cdbEntry).id.toString() ) {
				structure = Type.createInstance(e, [x, y, cdbEntry]);
			}
			// }
			// else
			// structure = new Blueprint(cdbEntry, parent);
		}
		structure = structure == null ? new Structure(x, y, cdbEntry) : structure;
		return structure;
	}

	override function dispose() {
		if ( cdbEntry != null ) {
			for (i in Data.structures.get(cdbEntry).drop) inline dropItem(Item.fromCdbEntry(i.item.id, i.amount));
			dropAllItems();
		}
		super.dispose();
	}
}
