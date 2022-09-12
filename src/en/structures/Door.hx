package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import game.server.ServerLevel;
import hxbit.Serializer;
import hxd.Event;
import hxd.Key;
import net.Server;
import net.ServerRPC;

class Door extends Structure {

	@:s public var leadsTo : String = "";

	public override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super.init( x, y, z, tmxObj );
		if ( tmxObj != null && tmxObj.properties.exists( "to" ) )
			leadsTo = Util.unifyLevelName( tmxObj.properties.getString( "to" ) );
	}

	override function alive() @:privateAccess {
		super.alive();
		interactable = true;

		interact.onTextInputEvent.add( onTextInput );
	}

	function onTextInput( e : Event ) {
		if ( Key.isPressed( Key.E ) ) {
			turnOffHighlight();

			if ( leadsTo != null ) {
				bringPlayerToLevel( Player.inst, leadsTo, ( e ) -> {} );
			}
		}
	}

	override function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return true;
	}

	@:rpc( server )
	function bringPlayerToLevel( player : Player, level : String ) : ServerLevel {
		player.footX.syncBack = player.footY.syncBack = true;
		var level = ServerRPC.bringPlayerToLevel(
			player,
			level,
			ServerRPC.putPlayerByDoorLeadingTo.bind( player, player.level.lvlName )
		);
		Server.inst.host.flush();
		player.footX.syncBack = player.footY.syncBack = false;
		return level;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
