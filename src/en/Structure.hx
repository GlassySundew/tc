package en;

import Level.StructTile;
import hxbit.Serializer;
import ui.InventoryGrid.CellGrid;
import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxObject;
import h2d.Bitmap;
import h3d.mat.Texture;
import hxd.Res;
import format.tmx.*;

class Structure extends Interactive {
	@:s public var cdbEntry : StructuresKind = null;
	public var toBeCollidedAgainst = true;

	public function new(x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : StructuresKind) {
		this.cdbEntry = cdbEntry;
		super(x, y, tmxObject);
	}

	public override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		// CDB parsed entry corresponding to this structure instance class name
		if ( cdbEntry == null ) try {
			eregClass.match('$this'.toLowerCase());
			cdbEntry = Data.structures.resolve(eregClass.matched(1)).id;
		}
		catch( Dynamic ) {}

		/**
			Initializing spr and making it static sprite from structures atlas as a
			class name if not initialized in custom structure class file
		**/
		if ( spr == null ) {
			spr = new HSprite(Assets.structures, entParent);
			eregClass.match('$this'.toLowerCase());
			try {
				spr.set(eregClass.matched(1));
			}
			catch( e:Dynamic ) {}
		}

		if ( cdbEntry == null ) try {
			cdbEntry = Data.structures.resolve(spr.groupName).id;
		}
		catch( Dynamic ) {}

		super.init(x, z, tmxObj);

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

		// Setting parameters from cdb entry
		if ( cdbEntry != null ) {
			useRange = Data.structures.get(cdbEntry).use_range;
			if ( useRange > 0 ) interactable = true;
			health = Data.structures.get(cdbEntry).hp;
			#if !headless
			if ( Data.structures.get(cdbEntry).isoHeight != 0 && Data.structures.get(cdbEntry).isoWidth != 0 ) {
				mesh.isLong = true;
				mesh.isoWidth = Data.structures.get(cdbEntry).isoWidth;
				mesh.isoHeight = Data.structures.get(cdbEntry).isoHeight;

				#if dispDepthBoxes
				mesh.renewDebugPts();
				#end
			}
			#end
		}
	}

	public function offsetFootByTile() {
		footY += (StructTile.polyPrim != null ? StructTile.polyPrim.getBounds().zSize / 2 - Level.inst.data.tileHeight : 0);
	}

	@:keep
	override function customSerialize(ctx : Serializer) {
		super.customSerialize(ctx);
	}

	@:keep
	override function customUnserialize(ctx : Serializer) {
		super.customUnserialize(ctx);
	}

	function dropAllItems(?angle : Float, ?power : Float) {
		if ( invGrid != null ) {
			for (i in invGrid.grid) {
				for (j in i) {
					if ( j.item != null ) {
						j.item = dropItem(j.item, angle == null ? Math.random() * M.toRad(360) : angle,
							power == null ? Math.random() * .03 * 48 + .01 : power);
					}
				}
			}
		}
	}

	public function applyItem(item : Item) {
		emitDestroyItem(item);
		if ( Data.items.get(item.cdbEntry).can_hit ) {
			// Damaging the structure
			if ( health > Data.items.get(item.cdbEntry).damage ) {
				health -= Data.items.get(item.cdbEntry).damage;
			} else {
				if ( cdbEntry != null ) {
					for (i in Data.structures.get(cdbEntry).drop) inline dropItem(Item.fromCdbEntry(i.item.id, i.amount));
					dropAllItems();
				}
				dispose();
			}
		} else {
			item.onStructureUse.dispatch();
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

	function initInv(gridConf : TmxObject) {
		if ( invGrid == null ) invGrid = new CellGrid(gridConf.properties.getInt("width"), gridConf.properties.getInt("height"),
			gridConf.properties.getInt("tileWidth"), gridConf.properties.getInt("tileHeight"));

		for (j in 0...invGrid.grid.length) {
			for (i in 0...invGrid.grid[j].length) {
				var tempInter = invGrid.grid[j][i];
				tempInter.inter.x = gridConf.x + i * (gridConf.properties.getInt("tileWidth") + gridConf.properties.getInt("gapX"));
				tempInter.inter.y = gridConf.y + j * (gridConf.properties.getInt("tileHeight") + gridConf.properties.getInt("gapY"));
			}
		}
	}

	public static function fromCdbEntry(x : Int, y : Int, cdbEntry : StructuresKind, ?amount : Int = 1) : Structure {
		var structure : Structure = null;
		var entClasses = (CompileTime.getAllClasses(Structure));
		for (e in entClasses) {
			if ( eregCompTimeClass.match('$e'.toLowerCase())
				&& eregCompTimeClass.matched(1) == Data.structures.get(cdbEntry).id.toString() ) {
				structure = Type.createInstance(e, [x, y, null, cdbEntry]);
			}
		}
		structure = structure == null ? new Structure(x, y, cdbEntry) : structure;
		return structure;
	}

	override function dispose() {
		super.dispose();
	}
}
