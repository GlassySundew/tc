package net;

import en.structures.Door;
import game.server.GameServer;
import en.player.Player;

/**
	collection of server-side rpc statics
**/
class ServerRPC {

	public static function bringPlayerToLevel(
		player : Player,
		level : String,
		?cb : Void -> Void
	) @:privateAccess {
		var fromLevel = player.level;

		var host = Server.inst.host;

		fromLevel.entities.remove( player );

		for ( ownerId => client in host.clientsOwners ) {
			if ( ownerId == player.clientController.__uid
				|| !client.ctx.refs.exists( player.__uid ) ) continue;
			player.unreg( host, client.ctx );
		}

		var ctx = host.isChannelingEnabled ? //
			host.clientsOwners[player.clientController.__uid].ctx : host.ctx;

		host.unregister( fromLevel, ctx );
		for ( e in fromLevel.entities )
			e.unreg( host, ctx );

		var toLevel = GameServer.inst.getLevel( level, {} );
		player.clientController.level = toLevel;
		player.level = toLevel;

		toLevel.entities.push( player );

		if ( cb != null ) cb();

		return toLevel;
	}

	public static function putPlayerByDoorLeadingTo( player : Player, leadingTo : String ) {
		var testDoor : Door = null;
		for ( i in player.level.entities )
			if ( i.isOfType( Door ) ) {
				testDoor = cast( i, Door );
				break;
			}

		var door = player.level.entities.filter( ( e ) -> return ( e.isOfType( Door ) && cast( e, Door ).leadsTo == leadingTo ) )[0];
		if ( door != null )
			player.setFeetPos( door.footX.val, door.footY.val );
	}
}
