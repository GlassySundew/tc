package net;

import en.player.Player;
import hxbit.NetworkHost.NetworkClient;
import hxbit.NetworkSerializable;

enum SaveSystemOrderType {
	CreateNewSave( name : String );
	// LoadGame( name : String );
	SaveGame( name : String );
	DeleteSave( name : String );
}

class ClientController implements NetworkSerializable {

	@:s public var uid( default, set ) : Int;

	@:s public var player( default, set ) : Player;
	@:s public var level( default, set ) : ServerLevel;

	public var networkClient : NetworkClient;

	/**
		check if we are the owner on this client ( should only be called on client )
	**/
	public var isOwner( get, never ) : Bool;

	function get_isOwner() : Bool return uid == Client.inst.uid;

	function set_player( player : Player ) {
		if ( player != null && GameClient.inst != null && isOwner ) {
			trace( "setting player" );
			emptyPing();
		}

		return this.player = player;
	}

	function set_level( level : ServerLevel ) {
		if ( Client.inst != null )
			trace( "got level " + level + ", isOwner " + isOwner + ", uid " + uid + " client uid " + Client.inst.uid );
		if ( GameClient.inst != null && level != null && isOwner ) {
			trace( "setting level" );
			GameClient.inst.sLevel = level;
			GameClient.inst.startLevelFromParsedTmx( level.tmxMap, level.lvlName );
		}

		return this.level = level;
	}

	function set_uid( v : Int ) {
		return uid = v;
	}

	public function new() {
		init();
	}

	public function alive() {
		init();

		trace( "aliving controller, uid " + uid + " isOwner - " + isOwner );

		if ( isOwner ) {
			Client.inst.host.self.ownerObject = this;
			Main.inst.clientController = this;
		}
	}

	// function customSerialize( ctx : hxbit.Serializer ) {}
	// function customUnserialize( ctx : hxbit.Serializer ) {}

	public function init() {
		if ( GameClient.inst != null ) {
			enableReplication = true;
		}
	}

	public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable ) : Bool {
		return clientSer == this;
	}

	@:rpc
	public function emptyPing() {}

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
