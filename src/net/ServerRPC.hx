package net;

import en.player.Player;

/**
	collection of server-side rpc statics
**/
class ServerRPC {

	public static function bringPlayerToLevel( player : Player, level : String ) @:privateAccess {
		var fromLevel = player.level;

		var host = Server.inst.host;

		fromLevel.removeEntity( player );

		for ( ownerId => client in host.clientsOwners ) {
			if ( ownerId == player.clientController.__uid
				|| !client.ctx.refs.exists( player.__uid ) ) continue;
			player.unreg( host, client.ctx );
		}

		var ctx = host.clientsOwners[player.clientController.__uid].ctx;
		host.unregister( fromLevel, ctx );
		for ( e in fromLevel.entities )
			e.unreg( host, ctx );

		var toLevel = GameServer.inst.getLevel( level, {} );
		player.clientController.level = toLevel;
		player.level = toLevel;

		toLevel.addEntity( player );

		return toLevel;
	}
}
