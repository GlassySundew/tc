package en.structures;

import util.Util;
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

	public function new( ?tmxObj : TmxObject ) {
		super( tmxObj );
	}

	public override function init() {
		super.init();
		if ( model.tmxObj != null && model.tmxObj.properties.exists( "to" ) )
			leadsTo = Util.unifyLevelName( model.tmxObj.properties.getString( "to" ) );
	}

	override function alive() {
		interactable = true;
		super.alive();

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
		player.model.footX.syncBack = player.model.footY.syncBack = true;
		var level = ServerRPC.bringPlayerToLevel(
			player,
			level,
			ServerRPC.putPlayerByDoorLeadingTo.bind( player, player.model.level.lvlName )
		);
		Server.inst.host.flush();
		player.model.footX.syncBack = player.model.footY.syncBack = false;
		return level;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
