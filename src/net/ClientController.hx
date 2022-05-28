package net;

import hxbit.NetworkHost.NetworkClient;
import en.player.Player;

enum SaveSystemOrderType {
	CreateNewSave( name : String );
	// LoadGame( name : String );
	SaveGame( name : String );
	DeleteSave( name : String );
}

class ClientController implements hxbit.NetworkSerializable {

	@:s public var uid : Int; // всегда должен быть наверху

	@:s public var player : Player;
	@:s public var level( default, set ) : ServerLevel;

	public var networkClient : NetworkClient;

	/**
		check if we are the owner on this client ( should only be called on client ofc )
	**/
	public var isOwner( get, never ) : Bool;

	inline function get_isOwner() : Bool return uid == Client.inst.uid;

	public function new() {
		init();
	}

	public function alive() {
		init();

		trace( "aliving controller" );

		if ( isOwner ) {
			Client.inst.host.self.ownerObject = this;
			Main.inst.clientController = this;
		}
	}

	public function init() {
		enableReplication = true;
	}

	public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable ) : Bool {
		trace( clientSer );

		return true;
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

	@:rpc( server )
	public function spawnPlayer( nickname : String ) {
		Server.inst.spawnPlayer( uid, nickname, this );
	}

	@:rpc( server )
	public function orderSaveSystem( type : SaveSystemOrderType ) : Bool {
		switch type {
			case CreateNewSave( name ):
				tools.Save.inst.makeFreshSave( name );
			case SaveGame( name ):
				tools.Save.inst.saveGame( name );
			case DeleteSave( name ):
				hxd.File.delete( Settings.SAVEPATH + name + Const.SAVEFILE_EXT );
		}

		return true;
	}
}
