import net.ClientController;
import hxd.File;
import tools.Save;
import hxbit.NetworkHost.NetworkClient;
import cherry.soup.EventSignal.EventSignal2;
import ui.Navigation;
import dn.Process;
import en.player.Player;
import hxd.net.SocketHost;
import Message;

/**
	server-side
	network host setup
**/
class Server extends Process {

	public static var inst : Server;

	static var parsedPort = Std.parseInt( Sys.getEnv( "PORT" ) );
	static var PORT : Int = parsedPort != null ? parsedPort : 6676;
	static var HOST = "0.0.0.0";

	public var host : SocketHost;
	public var uid : Int;

	public var game : GameServer;
	public var onTypedMessage : EventSignal2<NetworkClient, Message> = new EventSignal2();

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
					try {
						// cast(c.ownerObject, Cursor).dispose();
						trace( "error occured: " + e );
						host.unregister( c.ownerObject );
					}
					catch( e : Dynamic ) {
						trace( "error occured while unserizlizing " + e );
					}
				}
			);

			onTypedMessage.add( ( c, msg : Message ) -> {
				switch( msg ) {
					case ClientInit( uid ):
						var clientController = new ClientController();
						clientController.uid = uid;
						c.ownerObject = clientController;
						clientController.networkClient = c;
						c.sync();
					default:
				}
			} );

			#if debug
			onTypedMessage.add( ( client, message ) -> {
				switch( message ) {
					case GetServerStatus:
						host.sendMessage( ServerStatus( host.isAuth ), client );
					default:
				}
			} );
			#end

			host.onMessage = onTypedMessage.dispatch;

			// onTypedMessage.dispatch

			host.onUnregister = function ( c ) {
				log( 'unregistered ' + c );
			}

			log( "Server Started" );
			host.makeAlive();
			host.flush();
		}
		catch( e : Dynamic ) {
			log( "The 6676 port is already taken, server will not be booted..." );
		}
	}

	public function spawnPlayer( uid : Int, nickname : String, clientController : ClientController ) {

		log( "Client identified ( uid:" + uid + " nickname: " + nickname + ")" );

		var savedPlayerByNickname = null;
		//  Save.inst.getPlayerByNickname(nickname);

		var player : Player = null;
		if ( savedPlayerByNickname != null ) {
			// loading level

			// Save.inst.load
			// loading this bastard
			player = Save.inst.loadEntity( savedPlayerByNickname ).as( Player );
		} else {
			// slapping new player in entrypoint
			player = game.initializePlayer( nickname, uid );
		}

		// host.sendTypedMessage(MapLoad(player.level));

		// game.applyTmxObjOnEnt(cursorClient);
		// host.sendMessage(MapLoad(GameServer.inst.lvlName, GameServer.inst.tmxMap), c);

		clientController.player = player;
		clientController.level = player.level;
		clientController.uid = uid;
		clientController.networkClient.sync();
	}

	override function update() {
		super.update();
		host.flush();
	}

	public function log( s : String, ?pos : haxe.PosInfos ) {
		pos.fileName = ( host.isAuth ? "[S]" : "[C]" ) + " " + pos.fileName;
		haxe.Log.trace( s, pos );
	}
}
