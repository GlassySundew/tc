package en;

import ui.InventoryGrid.UICellGrid;
import en.player.Player;
import hxd.Key;
import Level.StructTile;
import format.tmx.Data.TmxObject;
import h2d.Bitmap;
import h3d.mat.Texture;
import hxbit.Serializer;
import hxd.Res;

class Structure extends Interactive {
	@:s public var cdbEntry : Data.StructureKind;
	public var toBeCollidedAgainst = true;

	public function new( x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : Data.StructureKind ) {
		this.cdbEntry = cdbEntry;
		super( x, y, tmxObject );
	}

	/**
		all serializable variables access in init(), unfortunately, have to be wrapped 
		around a delayer because all serializble vars are synced later on 
	**/
	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {

		// CDB parsed entry corresponding to this structure instance class name
		if ( cdbEntry == null ) try {
			eregClass.match( '$this'.toLowerCase() );
			cdbEntry = Data.structure.resolve( eregClass.matched( 1 ) ).id;
		}
		catch( e ) {
			// trace(e);
		}

		// Initializing spr and making it static sprite from structures atlas as a
		// class name if not initialized in custom structure class file

		if ( cdbEntry == null && spr != null ) try {
			cdbEntry = Data.structure.resolve( spr.groupName ).id;
		}
		catch( Dynamic ) {}

		super.init( x, z, tmxObj );
	}

	override function alive() {
		if ( spr == null ) {
			spr = new HSprite( Assets.structures, entParent );
			eregClass.match( '$this'.toLowerCase() );
			try {
				spr.set( eregClass.matched( 1 ) );
			}
			catch( e : Dynamic ) {
				trace( e );
			}
		}

		super.alive();

		// Setting parameters from cdb entry
		if ( cdbEntry != null ) {
			useRange = Data.structure.get( cdbEntry ).use_range;
			health = Data.structure.get( cdbEntry ).hp;

			if ( Data.structure.get( cdbEntry ).interactable ) {
				doHighlight = true;
				interactable = true;
			}

			if ( Data.structure.get( cdbEntry ).isoHeight != 0 && Data.structure.get( cdbEntry ).isoWidth != 0 ) {
				mesh.isLong = true;
				mesh.isoWidth = Data.structure.get( cdbEntry ).isoWidth;
				mesh.isoHeight = Data.structure.get( cdbEntry ).isoHeight;

				#if depth_debug
				mesh.renewDebugPts();
				#end
			}
		}

		// Нажатие для того, чтобы сломать структуру
		interact.onPushEvent.add( event -> {
			if ( GameClient.inst.player.holdItem != null ) applyItem( GameClient.inst.player.holdItem );
		} );
		interact.onOverEvent.add( ( _ ) -> {
			activateInteractive();
		} );
		interact.onOutEvent.add( ( e : hxd.Event ) -> {
			turnOffHighlight();
		} );
	}

	public function offsetFootByTile() {
		footY += 1.;
		// footY += ( StructTile.polyPrim != null ? ( StructTile.polyPrim.getBounds().zSize / 2 - Level.inst.data.tileHeight ) : 0 );
	}

	function dropAllItems( ?angle : Float, ?power : Float ) {
		if ( inventory != null ) {
			for ( i in inventory.grid ) {
				for ( j in i ) {
					if ( j.item != null ) {
						j.item = dropItem( j.item, angle == null ? Math.random() * M.toRad( 360 ) : angle,
							power == null ? Math.random() * .03 * 48 + .01 : power );
					}
				}
			}
		}
	}

	public function applyItem( item : Item ) {
		// this should not exist
		if ( health != -1 && Data.item.get( item.cdbEntry ).can_hit ) {
			emitDestroyItem( item );
			// Damaging the structure
			if ( health > Data.item.get( item.cdbEntry ).damage ) {
				health -= Data.item.get( item.cdbEntry ).damage;
			} else {
				if ( cdbEntry != null ) {
					for ( i in Data.structure.get( cdbEntry ).drop ) dropItem( Item.fromCdbEntry( i.item.id, null, i.amount ) );
					dropAllItems();
				}
				kill( Player.inst );
			}
		} else {
			item.onStructureUse.dispatch();
		}
	}

	public function emitDestroyItem( item : Item ) {
		// var hitPart = Res.hit_ico.toGpuParticlesClamped(mesh);
		// hitPart.z = 15;

		// @:privateAccess
		// {
		// 	hitPart.getGroup("main").texture = texture;
		// 	hitPart.materials[0].mainPass.depth(false, Less);
		// 	hitPart.getGroup("main").pshader.stopAt = 0.2;
		// 	hitPart.getGroup("main").emitMode = FlatInversedDisc;
		// }
		// hitPart.scale(hitPart.getGroup("main").size);
		// hitPart.getGroup("main").texture.filter = Nearest;

		// hitPart.rotate(M.toRad(M.randRange(-13, 13)), 0, 0);

		// hitPart.onEnd = () -> {
		// 	hitPart.remove();
		// 	hitPart = null;
		// };
	}

	public static function fromCdbEntry( x : Int, y : Int, cdbEntry : Data.StructureKind, ?amount : Int = 1 ) : Structure {
		var structure : Structure = null;
		var entClasses = ( CompileTime.getAllClasses( Structure ) );
		for ( e in entClasses ) {
			if ( eregCompTimeClass.match( '$e'.toLowerCase() )
				&& eregCompTimeClass.matched( 1 ) == Data.structure.get( cdbEntry ).id.toString() ) {
				structure = Type.createInstance( e, [x, y, null, cdbEntry] );
			}
		}
		structure = structure == null ? new Structure( x, y, cdbEntry ) : structure;
		return structure;
	}

	override function dispose() {
		super.dispose();
	}
}
