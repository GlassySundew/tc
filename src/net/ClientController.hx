package net;

import hxbit.MapProxy.MapData;
import en.player.Player;

class ClientController implements hxbit.NetworkSerializable {
	@:s public var uid : Int; // всегда должен быть наверху

	@:s public var player : Player;
	@:s public var level( default, set ) : ServerLevel;

	/**
		check if we are the owner on this client ( should only be called on client ofc )
	**/
	public var isOwner( get, never ) : Bool;

	inline function get_isOwner() : Bool return uid == Client.inst.uid;

	public function new() {
		init();
	}

	public function alive() {
		if ( isOwner ) {
			GameClient.inst.clientController = this;
			Client.inst.host.self.ownerObject = this;
		}

		init();
	}

	public function init() {
		enableReplication = true;
	}

	function set_player( player : Player ) {
		if ( player != null && player.level != null ) {
			player.clientController = this;
		}

		return this.player = player;
	}

	function set_level( level : ServerLevel ) {
		if ( GameClient.inst != null && level != null && isOwner ) {

			GameClient.inst.delayer.addF(() -> {
				GameClient.inst.sLevel = level;
				GameClient.inst.startLevelFromParsedTmx( level.tmxMap, level.lvlName );
			}, 1 );
		}

		return this.level = level;
	}
}
