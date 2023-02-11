package net;

import util.tools.Settings;
import dn.Process;
import en.player.Player;
import game.server.GameServer;
import hxbit.NetworkHost.NetworkClient;
import hxd.net.SocketHost;
import net.ClientController;
import util.Env;
import util.tools.Save;

using util.Extensions.SocketHostExtender;

/**
	server-side
	network host setup
**/
@:build( util.Macros.buildServerMessagesSignals() )
class Server extends Process {

	public static var inst : Server;

	static var parsedPort = Std.parseInt( Sys.getEnv( "PORT" ) );
	static var PORT : Int = parsedPort != null ? parsedPort : 6676;
	static var HOST = "0.0.0.0";

	public var host : SocketHost;
	public var uid : Int;

	public var game : GameServer;

	public function new( ?seed : String ) {
		super();
		inst = this;

		Env.init();
		Settings.init();
		Save.initFields();

		#if( hl && pak )
		hxd.Res.initPak();
		#elseif( hl )
		hxd.Res.initLocal();
		#end

		if ( seed == null ) seed = Random.string( 10 );

		new Save();

		if ( GameServer.inst != null ) {
			GameServer.inst.destroy();
			game = new GameServer( seed );
		} else
			game = new GameServer( seed );

		startServer();
	}

	/**
		added in favor of unserializing

		@param mockConstructor if true, then we will execute dn.Process constructor clause
	**/
	public function initLoad( ?mockConstructor = true ) {
		if ( mockConstructor ) {
			init();

			if ( parent == null ) Process.ROOTS.push( this ); else
				parent.addChild( this );
		}

		inst = this;
	}

	function startServer() {
		host = new hxd.net.SocketHost();
		host.setLogger( function ( msg ) {
			#if network_debug
			log( msg );
			#end
		} );

		try {
			@:privateAccess
			host.waitFixed( HOST, PORT,
				function ( c ) {
					log( "Client Connected" );
				},
				function ( c : SocketClient, e : String ) {
					if ( c.host != null ) {
						destroyClient( c );
					}
				}
			);

			onClientInitMessage.add( ( c, uid ) -> {
				var clientController = new ClientController();
				clientController.uid = uid;
				c.ownerObject = clientController;
				clientController.networkClient = c;

				@:privateAccess host.register( clientController, c.ctx );
				c.sync();
			} );

			#if debug
			onGetServerStatusMessage.add( ( client ) -> {
				host.sendMessage( net.Message.ServerStatus( host.isAuth ), client );
			} );
			#end
			host.onMessage = onMessage;

			host.onUnregister = function ( c ) {
				log( 'unregistered ' + c );
			}

			log( "Server Started" );
			host.makeAlive();
		} catch( e : Dynamic ) {
			log( "port 6676 is already taken, server will not be booted..." );
		}
	}

	public function destroyClient( c : SocketClient ) {
		var cc = cast( c.ownerObject, ClientController );
		if ( cc.__host == null ) return;
		if ( cc.player != null ) cc.player.destroy();
		for ( i => client in host.clientsOwners ) {
			cc.unreg( host, client.ctx, i + 1 == host.clients.length );
		}
	}

	override function postUpdate() {
		super.postUpdate();
		host.flush();
	}

	public function log( s : String, ?pos : haxe.PosInfos ) {
		pos.fileName = ( host.isAuth ? "[S]" : "[C]" ) + " " + pos.fileName;
		haxe.Log.trace( s, pos );
	}
}
