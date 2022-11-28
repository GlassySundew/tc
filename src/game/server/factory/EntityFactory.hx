package game.server.factory;

import ui.core.InventoryGrid;
import en.model.InventoryModel;
import en.Entity;
import en.SpriteEntity;
import en.player.Player;
import format.tmx.Data;
import net.ClientController;
import net.Server;
import util.EregUtil;
import util.tools.Save;

using en.util.EntityUtil;
using util.Extensions.TmxPropertiesExtension;

class EntityFactory {

	public var game : GameServer;

	public function new() {}

	public function spawnPlayer(
		uid : Int,
		nickname : String,
		clientController : ClientController
	) {
		Server.inst.log( "Client identified ( uid:" + uid + " nickname: " + nickname + ")" );

		var savedPlayerByNickname = null;
		//  Save.inst.getPlayerByNickname(nickname);

		var player : Player = null;
		if ( savedPlayerByNickname != null ) {
			// Save.inst.load
			// loading this bastard
			player = Std.downcast( Save.inst.loadEntity( savedPlayerByNickname ), Player );
		} else {
			// slapping new player in entrypoint
			player = newPlayer( nickname, uid, clientController );
		}

			// Server.inst.host.mark( c.ownerObject );
		// Server.inst.host.flush();

		// GameServer.inst.delayer.addF(()->{
		player.playerModel.nickname = nickname;
		@:privateAccess
		player.__net_mark_playerModel(player.playerModel);
		
		// }, 1);
		player.model.controlId = uid;
		player.clientController = clientController;

		clientController.uid = uid;
		clientController.level = player.model.level;
		clientController.player = player;

	
	}

	/**
		starts entrypoint level if doesnt exists and slaps player onto it
	**/
	public function newPlayer(
		nickname : String,
		uid : Int,
		clientController : ClientController
	) : Player {
		// our temporary entrypoint
		var entryPointLevel = "ship_pascal.tmx";

		var sLevel = game.getLevel( entryPointLevel, {} );
		// раз игрок новый, то спавним его из tmxObject
		var player = Std.downcast(
			searchAndSpawnEnt( sLevel.player, GameServer.entClasses, sLevel ),
			Player
		);

		return player;
	}

	// Search for name from parsed entNames Entity classes and spawn it, creates static SpriteEntity and puts name into spr group if not found
	public function searchAndSpawnEnt(
		e : TmxObject,
		entClasses : List<Class<Entity>>,
		sLevel : ServerLevel
	) : Entity {

		var resultEntity : Entity = null;
		var footZ : Float =
			sLevel.tmxMap.properties.getProp(
				PTInt,
				"defaultEntitySpawnLevel",
				() -> return e.properties.getProp( PTInt, "z" )
			) * sLevel.tmxMap.tileHeight + 1;

		var x = e.x + footZ;
		var y = e.y + footZ;
		var tsTile : TmxTilesetTile = null;

		switch e.objectType {
			case OTTile( gid ):
				tsTile = format.tmx.Tools.getTileByGid( sLevel.tmxMap, gid );
			default:
		}
		if ( tsTile == null ) return null;

		// Парсим все классы - наследники en.Entity и спавним их
		for ( eClass in entClasses ) {
			// смотрим во всех наследников Entity и спавним, если совпадает. Если не совпадает, то
			// значит что потом мы смотрим настройку className тайла из тайлсета, который мы пытаемся заспавнить
			if ( (
				EregUtil.eregCompTimeClass.match( '$eClass'.toLowerCase() )
				&& EregUtil.eregCompTimeClass.matched( 1 ) == e.name
			) || (
				tsTile.properties.existsType( "className", PTString )
				&& tsTile.properties.getString( "className" ) == '$eClass'
			)
			) {
				resultEntity = Type.createInstance( eClass, [e] );
			}
		}

		// если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
		if (
			resultEntity == null
			&& EregUtil.eregFileName.match( tsTile.image.source )
			&& !tsTile.properties.existsType( "className", PTString ) //
		) {
			resultEntity = new SpriteEntity( EregUtil.eregFileName.matched( 1 ), e );
		}

		if ( resultEntity != null ) @:privateAccess {
			resultEntity.model.level = sLevel;
			sLevel.entities.push( resultEntity );
			resultEntity.serverApplyTmx();
			resultEntity.setFeetPos( x, y, footZ );
		}

		// Inventorizer.inventorize( resultEntity );
		// resultEntity.enableAutoReplication = true;
		return resultEntity;
	}
}

@:allow( game.server.factory.EntityFactory )
class Inventorizer {

	static inline function inventorize( e : Entity ) {
		var inventoryModel : InventoryModel = Reflect.field( e, "inventoryModel" );
		if ( inventoryModel == null ) return;

		var cdb = e.model.cdb;
		var cdbInv = Data.inventory.all.filter( ( inv ) -> inv.entityId == cdb )[0];
		if ( cdbInv == null ) return;

		inventoryModel.inventory = new InventoryGrid( cdbInv.width, cdbInv.height, Chest, e );
	}
}
