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

	public function spawnEntity( e : TmxObject, sLevel : ServerLevel ) {
		var entitySpawner = new EntitySpawner( entityFactoryMediator );
		entitySpawner.e = e;
		entitySpawner.sLevel = sLevel;
		entitySpawner.spawn();
	}

	public inline function spawnPlayer( uid, nickname, clientController ) {
		var playerSpawner = new PlayerSpawner( entityFactoryMediator );
		playerSpawner.uid = uid;
		playerSpawner.game = GameServer.inst;
		playerSpawner.nickname = nickname;
		playerSpawner.clientController = clientController;

		playerSpawner.spawnPlayer();
	}
}
