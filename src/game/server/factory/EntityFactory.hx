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

	public var entityFactoryMediator : EntityFactoryMediator;

	public function new() {
		entityFactoryMediator = new EntityFactoryMediator( GameServer.entClasses );
	}

	public function spawnEntity( obj : TmxObject, sLevel : ServerLevel ) {
		var entitySpawner = new EntitySpawner( entityFactoryMediator );
		entitySpawner.tmxData.obj = obj;
		entitySpawner.sLevel = sLevel;
		entitySpawner.spawn();
	}

	public inline function spawnPlayer(
		uid : Int,
		nickname : String,
		clientController : ClientController
	) {
		Server.inst.log( "Client identified ( uid:" + uid + " nickname: " + nickname + ")" );

		var playerSpawner = new PlayerSpawner( entityFactoryMediator );
		playerSpawner.uid = uid;
		playerSpawner.game = game;
		playerSpawner.nickname = nickname;
		playerSpawner.cliCon = clientController;

		var savedPlayerByNickname = null;
		//  Save.inst.getPlayerByNickname(nickname);

		var player = if ( savedPlayerByNickname != null ) {
			// Save.inst.load
			// loading this bastard
			Std.downcast( Save.inst.loadEntity( savedPlayerByNickname ), Player );
		} else {
			// slapping new player in entrypoint
			playerSpawner.newPlayer();
		}

		// playerSpawner;
	}
}
