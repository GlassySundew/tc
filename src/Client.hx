import cherry.soup.EventSignal.EventSignal0;
import Level.StructTile;
import MainMenu.TextButton;
import dn.Process;
import en.player.Player;
import h2d.Flow;
import tools.Settings;
import ui.ShadowedText;

class Client extends Process {
	static var HOST = "127.0.0.1";
	// static var HOST = "78.24.222.152";
	static var PORT = 6676;

	public static var inst : Client;

	public var host : hxd.net.SocketHost;
	public var uid : Int;
	public var seed : String;

	public var structTiles : Array<StructTile> = [];
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

		uid = 1 + Std.random( 1000 );

		host.connect( HOST, PORT, function ( b ) {
			if ( !b ) {
				// server not found
				var infoFlow = new Flow( Boot.inst.s2d );
				infoFlow.verticalAlign = Middle;
				var textInfo = new ShadowedText( Assets.fontPixel, infoFlow );
				textInfo.text = "unable to connect... ";

				var mainMenuBut : TextButton = null;
				mainMenuBut = new TextButton( "return back to menu", ( e ) -> {
					mainMenuBut.cursor = Default;
					infoFlow.remove();
					destroy();
					new MainMenu( Boot.inst.s2d );
				}, infoFlow );

				trace( "Failed to connect to server" );
				return;
			}

			trace( "Connected to server", uid );

			onConnection.dispatch();
			connected = true;

			sendMessage( Message.PlayerBoot( uid, Settings.params.nickname ) );

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
			switch( msg ) {
				case MapLoad( name, map ):

				case WorldInfo( seed ):
					this.seed = seed;
				default:
			}
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
			connected = false;
			trace( "looks like the server you were connected to is closed" );
		};

		@:privateAccess Main.inst.onClose.add(() -> {
			connected = false;
			try {
				Player.inst.destroy();
				host.unregister( Player.inst );
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

	public function log( s : String, ?pos : haxe.PosInfos ) {
		pos.fileName = ( host.isAuth ? "[S]" : "[C]" ) + " " + pos.fileName;
		haxe.Log.trace( s, pos );
	}

	public function sendMessage( msg : Message ) {
		host.sendMessage( msg );
	}
}
