package en;

import dn.M;
import utils.Util;
import en.spr.EntitySprite;
import game.client.GameClient;
import game.client.GameClient;
import utils.Assets;
import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;

using en.util.EntityUtil;

class Structure extends en.InteractableEntity {

	@:s public var cdbEntry : Data.EntityKind;
	public var toBeCollidedAgainst = true;
	public var health : Float;

	public function new( x = 0., y = 0., z = 0., ?tmxObject : TmxObject, ?cdbEntry : Data.EntityKind ) {
		this.cdbEntry = cdbEntry;
		super( x, y, z, tmxObject );

		// CDB parsed entry corresponding to this structure instance class name
		if ( cdbEntry == null ) try {
			Util.eregClass.match( '$this'.toLowerCase() );
			cdbEntry = Data.entity.resolve( Util.eregClass.matched( 1 ) ).id;
		}
		catch( e ) {
			// trace(e);
		}
	}

	public override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		// Initializing spr and making it static sprite from structures atlas as a
		// class name if not initialized in custom structure class file

		if ( cdbEntry == null && eSpr != null ) try {
			cdbEntry = Data.entity.resolve( eSpr.spr.groupName ).id;
		}
		catch( Dynamic ) {}

		super.init( x, y, z, tmxObj );
	}

	override function alive() {
		if ( eSpr == null ) {
			eSpr = new EntitySprite( this, Assets.structures, Util.hollowScene );
			Util.eregClass.match( '$this'.toLowerCase() );
			try {
				eSpr.setSprGroup( Util.eregClass.matched( 1 ) );
			} catch( e : Dynamic ) {
				trace( e );
			}
		}

		super.alive();

		// Setting parameters from cdb entry
		if ( cdbEntry != null ) {
			useRange = Data.entity.get( cdbEntry ).use_range;
			health = Data.entity.get( cdbEntry ).hp;

			if ( Data.entity.get( cdbEntry ).interactable ) {
				doHighlight = true;
				interactable = true;
			}

			if ( Data.entity.get( cdbEntry ).isoHeight != 0 && Data.entity.get( cdbEntry ).isoWidth != 0 ) {
				eSpr.mesh.isoWidth = Data.entity.get( cdbEntry ).isoWidth;
				eSpr.mesh.isoHeight = Data.entity.get( cdbEntry ).isoHeight;
				eSpr.mesh.refreshVerts();

				#if depth_debug
				eSpr.mesh.renewDebugPts();
				#end
			}
		}

		// Нажатие для того, чтобы сломать структуру
		interact.onPushEvent.add( event -> {
			if ( GameClient.inst.player.holdItem != null ) applyItem( GameClient.inst.player.holdItem.item );
		} );
		interact.onOverEvent.add( ( _ ) -> {
			activateInteractive();
		} );
		interact.onOutEvent.add( ( e : hxd.Event ) -> {
			turnOffHighlight();
		} );

		Main.inst.delayer.addF(() -> {
			interactCheck();
		}, 10 );
	}

	function activateInteractive() {
		if ( interactable && isInPlayerRange() ) {
			if ( doHighlight )
				turnOnHighlight();
			return true;
		} else
			return false;
	}

	function updateInteract() {
		if ( interactable ) updateKeyIcon();
		if ( interact != null && Player.inst != null && Player.inst.isMoving )
			interactCheck();
	}

	function interactCheck() {
		interact.visible =
			interactable
			&& Player.inst != null
			&& !Player.inst.destroyed
			&& isInPlayerRange();
	}

	function isInPlayerRange() return this.distPolyToPt( Player.inst ) <= useRange;

	public function offsetFootByTile() {
		footY.val += 1.;
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
					for ( i in Data.entity.get( cdbEntry ).drop ) dropItem( Item.fromCdbEntry( i.item.id, null, i.amount ) );
					dropAllItems();
				}
				kill( Player.inst );
			}
		} else {
			item.onStructureUse.dispatch();
		}
	}

	@:rpc( server )
	public function useByEntity( ent : Entity ) {}

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

	override function postUpdate() {
		super.postUpdate();
		updateInteract();
	}

	public static function fromCdbEntry( x : Int, y : Int, cdbEntry : Data.EntityKind, ?amount : Int = 1 ) : Structure {
		var structure : Structure = null;
		var entClasses = ( CompileTime.getAllClasses( Structure ) );
		for ( e in entClasses ) {
			if ( Util.eregCompTimeClass.match( '$e'.toLowerCase() )
				&& Util.eregCompTimeClass.matched( 1 ) == Data.entity.get( cdbEntry ).id.toString() ) {
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
