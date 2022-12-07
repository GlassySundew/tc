package game.server.factory;

import format.tmx.Data.TmxObject;
import en.Entity;
import util.tools.Save;
import en.player.Player;
import net.Server;
import net.ClientController;

class PlayerSpawner extends EntitySpawner {

	public var game : GameServer;

	public var uid : Int;
	public var nickname : String;
	public var clientController : ClientController;

	public function spawnPlayer() : Player {
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
			player = newPlayer();
		}

		return player;
	}

	/**
		starts entrypoint level if doesnt exists and slaps player onto it
	**/
	public function newPlayer() : Player {
		// TODO our temporary entrypoint
		var entryPointLevel = "ship_pascal.tmx";

		var sLevel = game.getLevel( entryPointLevel, {} );
		// раз игрок новый, то спавним его из tmxObject
		this.sLevel = sLevel;
		this.e = sLevel.player;
		var player = Std.downcast( spawn(), Player );

		return player;
	}

	override function submitToLevel( resultEntity : Entity, sLevel : ServerLevel ) {
		var player = Std.downcast( resultEntity, Player );

		player.playerModel.nickname = nickname;
		player.model.controlId = uid;		player.clientController = clientController;

		clientController.uid = uid;
		clientController.player = player;

		super.submitToLevel( resultEntity, sLevel );

		clientController.level = player.model.level;
	}
}
