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
	public var cliCon : ClientController;

	/**
		starts entrypoint level if doesnt exists and slaps player onto it
	**/
	public function newPlayer() : Player {
		// TODO our temporary entrypoint
		var entryPointLevel = "ship_pascal.tmx";

		var sLevel = game.getLevel( entryPointLevel );
		// раз игрок новый, то спавним его из tmxObject
		this.sLevel = sLevel;
		tmxData = sLevel.player;

		var player = Std.downcast( spawn(), Player );
		return player;
	}

	override function submitToLevel(
		resultEntity : Entity,
		sLevel : ServerLevel
	) {
		var player = Std.downcast( resultEntity, Player );

		player.playerModel.nickname = nickname;
		player.model.controlId = uid;
		player.clientController = cliCon;
		sLevel.chunks.attachWatcherEntity(
			player,
			cliCon.networkClient.ctx,
			cliCon.channelContainer
		);

		cliCon.uid = uid;
		cliCon.player = player;

		super.submitToLevel( resultEntity, sLevel );
	}
}
