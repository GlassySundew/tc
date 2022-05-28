import utils.Repeater;
import Level.StructTile;
import cherry.soup.EventSignal.EventSignal0;
import cherry.soup.EventSignal.EventSignal2;
import dn.Process;
import h2d.Flow;
import hxbit.NetworkHost.NetworkClient;
import tools.Settings;
import ui.ShadowedText;
import ui.TextButton;

class Client extends Process {

	static var PORT = 6676;

	public static var inst : Client;

	public var host : hxd.net.SocketHost;
	public var uid : Int;
	public var seed : String;

	public var onConnection : EventSignal0;

	public var connected = false;

	public function new() {
		super( Main.inst );
		inst = this;

		onConnection = new EventSignal0();

		host = new hxd.net.SocketHost();
		host.setLogger( function ( msg ) {
			#if network_debug
			log( msg );
			#end
		} );

		Main.inst.onClose.add(() -> {
			try {
				host.dispose();
				if ( GameClient.inst != null )
					GameClient.inst.gc();
			}
			catch( e : Dynamic ) {
				trace( "error occured while disposing: " + e );
			}
			host.flush();
		} );
	}

	public function repeatConnect( interval = 0.5, repeats = 6 ) {
		connect();
		if ( !connected ) {
			addOnConnectionCallback(() -> {
				Repeater.inst.unset( "connect" );
			} );

			Repeater.inst.setS( "connect", interval, repeats, () -> {
				connect();
			} );
		}
	}

	static var infoFlow : Flow;

	public function connect( hostIp = "127.0.0.1", ?onFail : Void -> Void ) {
		trace( "trying to connect" );

		uid = 1 + Std.random( 1000 );

		host.connect( hostIp, PORT, function ( b ) {
			if ( !b ) {
				if ( !Repeater.inst.has( "connect" ) ) {
					if ( infoFlow != null )
						infoFlow.remove();

					// server not found
					infoFlow = new Flow( Boot.inst.s2d );
					infoFlow.verticalAlign = Middle;
					var textInfo = new ShadowedText( Assets.fontPixel, infoFlow );
					textInfo.text = "unable to connect... ";

					var mainMenuBut : TextButton = null;
					mainMenuBut = new TextButton( "return back to menu", ( e ) -> {
						mainMenuBut.cursor = Default;
						infoFlow.remove();
						destroy();
						MainMenu.spawn( Boot.inst.s2d );
					}, infoFlow );
					infoFlow.getProperties(mainMenuBut).verticalAlign = Bottom;

					trace( "Failed to connect to server" );
				}
				return;
			}
			if ( infoFlow != null )
				infoFlow.remove();

			trace( "Connected to server", uid );

			sendMessage( Message.ClientInit( uid ) );

			onConnection.dispatch();
			connected = true;
		} );

		host.onMessage = ( c, msg : Message ) -> {
			switch( msg ) {
				case MapLoad( name, map ):

				case WorldInfo( seed ):
					this.seed = seed;
				default:
			}
		}

		host.onUnregister = function ( o ) {
			trace( "client disconnected " + o );
		};
	}

	public function addOnConnectionCallback( callback : Void -> Void ) {
		if ( connected )
			callback();
		else
			onConnection.add( callback, true );
	}

	override function update() {
		super.update();
		host.flush();
	}

	public function disconnect() {
		try {
			host.dispose();
		} catch( e ) {
			trace( e );
		}
	}

	public function log( s : String, ?pos : haxe.PosInfos ) {
		pos.fileName = ( host.isAuth ? "[S]" : "[C]" ) + " " + pos.fileName;
		haxe.Log.trace( s, pos );
	}

	public function sendMessage( msg : Message ) {
		host.sendMessage( msg );
	}
}

class DebugClient extends Process {

	static var HOST = "127.0.0.1";
	// static var HOST = "78.24.222.152";
	static var PORT = 6676;

	public static var inst : DebugClient;

	public var host : hxd.net.SocketHost;
	public var uid : Int;
	public var seed : String;

	public var onConnection : EventSignal0;

	public var connected = false;

	public var onTypedMessage : EventSignal2<NetworkClient, Message> = new EventSignal2();

	public function new() {
		super( Main.inst );
		inst = this;

		onConnection = new EventSignal0();

		host = new hxd.net.SocketHost();
		host.setLogger( function ( msg ) {
			#if network_debug
			log( msg );
			#end
		} );

		uid = 1 + Std.random( 1000 );

		host.connect( HOST, PORT, function ( b ) {
			if ( !b ) {
				trace( "Failed to connect to server" );
				return;
			}

			trace( "Connected to server", uid );

			onConnection.dispatch();
			connected = true;

			// sys.thread.Thread.create(() -> {
			// 	while( true ) {
			// 		Sys.sleep(100);
			// 		try {
			// 			host.sendMessage({type: "ping", msg: uid});
			// 		}
			// 		catch( e:Dynamic  ) {
			// 			break;
			// 		}
			// 	}
			// });
		} );

		host.onMessage = ( c, msg : Message ) -> {
			trace( "got something " + msg );

			onTypedMessage.dispatch( c, msg );
		}
		// host.onMessage = function(c, msg:Message) {
		// 	switch( msg.type ) {
		// 		case mapLoad:
		// 			var map = cast(msg, MapLoad);
		// 			loadMap(map.map);
		// 			trace("ZHOPA");

		// 		default:
		// 	}
		// }

		host.onUnregister = function ( o ) {
			trace( "client disconnected " + o );
		};

		Main.inst.onClose.add(() -> {
			connected = false;
			try {
				host.dispose();
				GameClient.inst.gc();
			}
			catch( e : Dynamic ) {
				trace( "error occured while disposing: " + e );
			}
			host.flush();
		} );
	}

	override function update() {
		super.update();
		host.flush();
	}

	public function disconnect() {
		try {
			host.dispose();
		} catch( e ) {
			trace( e );
		}
	}

	#if debug
	public function requestServerStatus( callback : Message -> Void ) {
		onTypedMessage.add( function ( client, message ) {
			callback( message );
		} );
		sendMessage( GetServerStatus );
	}
	#end

	public function log( s : String, ?pos : haxe.PosInfos ) {
		pos.fileName = ( host.isAuth ? "[S]" : "[C]" ) + " " + pos.fileName;
		haxe.Log.trace( s, pos );
	}

	public function sendMessage( msg : Message ) {
		host.sendMessage( msg );
	}
}
