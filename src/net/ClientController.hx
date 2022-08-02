package net;

import hxbit.NetworkHost;
import net.transaction.Transaction;
import game.client.GameClient;
import game.server.ServerLevel;
import en.player.Player;
import hxbit.NetworkHost.NetworkClient;
import hxbit.NetworkSerializable;
import utils.tools.Save;

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
			emptyPing();
		}

		return this.player = player;
	}

	function set_level( level : ServerLevel ) {
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
		if ( !Server.inst.host.isAutoOwner ) enableReplication = true;
	}

	public function alive() {
		enableReplication = true;

		if ( isOwner ) {
			Client.inst.host.self.ownerObject = this;
			Main.inst.clientController = this;
		} else
			if ( Client.inst.host.isAutoOwner ) throw "clientController instance is replicated on a client where it is not supposed to be";
	}

	// function customSerialize( ctx : hxbit.Serializer ) {}
	// function customUnserialize( ctx : hxbit.Serializer ) {}

	public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable ) : Bool {
		return clientSer == this;
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer, ?finalize ) @:privateAccess {
		if ( ctx.refs.exists( player.__uid ) )
			host.unregister( player, ctx, finalize );
	}

	/**
		коостыль для бага, нужен любой rpc вызов чтобы 
		подгрузить ServerLevel после подключения
	**/
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
				Save.inst.makeFreshSave( name );
			case SaveGame( name ):
				Save.inst.saveGame( name );
			case DeleteSave( name ):
				hxd.File.delete( Settings.SAVEPATH + name + Const.SAVEFILE_EXT );
		}

		return true;
	}

	@:rpc( server )
	public function sendTransaction( t : Transaction ) : TransactionResult {
		return t.validate();
	}
}
