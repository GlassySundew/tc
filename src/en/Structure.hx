package en;

import game.server.GameServer;
import net.Server;
import en.util.CdbUtil;
import en.model.StructureModel;
import en.model.HealthModel;
import en.model.InventoryModel;
import dn.M;
import util.Util;
import en.spr.EntityView;
import game.client.GameClient;
import game.client.GameClient;
import util.Assets;
import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;
import util.EregUtil;

using en.util.EntityUtil;

class Structure extends en.InteractableEntity {

	public static var CLIENT_STRUCTURES : Array<Structure> = [];

	@:s public var inventoryModel : InventoryModel;
	@:s public var healthModel : HealthModel;
	@:s public var structureModel : StructureModel;

	public function new( ?tmxObject : TmxObject ) {
		inventoryModel = new InventoryModel();
		healthModel = new HealthModel();
		structureModel = new StructureModel();

		super( tmxObject );

		model.cdb.onAppear( ( v ) -> {
			structureModel.structureCdb = CdbUtil.getEntry(
				v,
				"entity",
				Data.structure.all
			);
		} );
	}

	public override function init() {
		super.init();
	}

	override function alive() {
		super.alive();
		CLIENT_STRUCTURES.push( this );
	}

	override function createView() {
		if ( eSpr == null ) {
			eSpr = new EntityView( this, Assets.structures, Util.hollowScene );
			if ( EregUtil.eregClass.match( '$this'.toLowerCase() ) )
				try {
					eSpr.setSprGroup( EregUtil.eregClass.matched( 1 ) );
				} catch( e : Dynamic ) {
					trace( e );
				}
		}
		super.createView();

		// Нажатие для того, чтобы сломать структуру
		interact.onPushEvent.add( event -> {
			if ( GameClient.inst.player.inventoryModel.holdItem != null )
				applyItem( GameClient.inst.player.inventoryModel.holdItem.item );
		} );
		interact.onOverEvent.add( turnOnHighlight );
		interact.onOutEvent.add( ( e : hxd.Event ) -> {
			turnOffHighlight();
		} );
	}

	public function offsetFootByTile() {
		model.footY.val += 1.;
		// footY += ( StructTile.polyPrim != null ? ( StructTile.polyPrim.getBounds().zSize / 2 - Level.inst.data.tileHeight ) : 0 );
	}

	function dropAllItems( ?angle : Float, ?power : Float ) {
		// if ( inv.inventory != null ) {
		// 	for ( i in inv.inventory.grid ) {
		// 		for ( j in i ) {
		// 			if ( j.item != null ) {
		// 				j.item = dropItem( j.item, angle == null ? Math.random() * M.toRad( 360 ) : angle,
		// 					power == null ? Math.random() * .03 * 48 + .01 : power );
		// 			}
		// 		}
		// 	}
		// }
	}

	public function applyItem( item : Item ) {
		// if ( health != -1 && Data.item.get( item.cdbEntry ).can_hit ) {
		// 	emitDestroyItem( item );
		// 	// Damaging the structure
		// 	if ( health > Data.item.get( item.cdbEntry ).damage ) {
		// 		health -= Data.item.get( item.cdbEntry ).damage;
		// 	} else {
		// 		if ( cdbEntry != null ) {
		// 			for ( i in Data.entity.get( cdbEntry ).drop ) dropItem( Item.fromCdbEntry( i.item.id, null, i.amount ) );
		// 			dropAllItems();
		// 		}
		// 		kill( Player.inst );
		// 	}
		// } else {
		// 	item.onStructureUse.dispatch();
		// }
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

	public static function fromCdbEntry( x : Int, y : Int, cdbEntry : Data.EntityKind, ?amount : Int = 1 ) : Structure {
		var structure : Structure = null;
		var entClasses = ( CompileTime.getAllClasses( Structure ) );
		for ( e in entClasses ) {
			if ( EregUtil.eregCompTimeClass.match( '$e'.toLowerCase() )
				&& EregUtil.eregCompTimeClass.matched( 1 ) == Data.entity.get( cdbEntry ).id.toString() ) {
				structure = Type.createInstance( e, [null, cdbEntry] );
			}
		}
		structure = structure == null ? new Structure() : structure;
		return structure;
	}

	override function dispose() {
		super.dispose();
		CLIENT_STRUCTURES.remove( this );
	}
}
