package net;

import en.player.PlayerChannelContainer;
import util.Const;
import util.tools.Settings;
import hxbit.NetworkHost;
import net.transaction.Transaction;
import game.client.GameClient;
import game.server.ServerLevel;
import en.player.Player;
import hxbit.NetworkHost.NetworkClient;
import hxbit.NetworkSerializable;
import util.tools.Save;

enum SaveSystemOrderType {
	CreateNewSave( name : String );
	// LoadGame( name : String );
	SaveGame( name : String );
	DeleteSave( name : String );
}

class ClientController extends NetNode {

	@:s public var uid( default, set ) : Int;
	@:s public var player( default, set ) : Player;
	@:s public var channelContainer : PlayerChannelContainer;

	function set_uid( v : Int ) {
		return uid = v;
	}

	/** server-side **/
	public var networkClient : NetworkClient;

	/**
		client-side
		check if we are the owner on this client
	**/
	public var isOwner( get, never ) : Bool;

	function get_isOwner() : Bool return uid == Client.inst.uid;

	function set_player( player : Player ) {
		if ( player != null && GameClient.inst != null && isOwner ) {

			emptyPing();
		}

		return this.player = player;
	}

	public function new() {
		super();
		channelContainer = new PlayerChannelContainer( this );
	}

	override public function alive() {
		super.alive();

		if ( isOwner ) {
			Client.inst.host.self.ownerObject = this;
			Main.inst.cliCon.val = this;
		} else
			if ( Client.inst.host.isChannelingEnabled )
				throw "clientController instance is replicated on a client where it is not supposed to be";
	}

	// function customSerialize( ctx : hxbit.Serializer ) {}
	// function customUnserialize( ctx : hxbit.Serializer ) {}

	public override function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return clientSer == this;
	}

	public function unreg(
		host : NetworkHost,
		ctx : NetworkSerializer,
		?finalize
	) @:privateAccess {
		if ( player != null && ctx.refs.exists( player.__uid ) )
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
		Server.inst.game.entityFactory.spawnPlayer( uid, nickname, this );
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
