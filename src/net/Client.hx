package net;

import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import game.client.GameClient;
import h2d.Flow;
import ui.MainMenu;
import ui.core.ShadowedText;
import ui.core.TextButton;
import ui.dialog.ConfirmDialog;
import utils.Assets;
import utils.Repeater;

class Client extends Process {

	static var PORT = 6676;

	public static var inst : Client;

	public var host : hxd.net.SocketHost;
	public var uid : Int;
	public var seed : String;

	public var onConnection : EventSignal0;

	public var connected( get, never ) : Bool;

	function get_connected() @:privateAccess return host.connected;

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
				sendMessage( Disconnect );
				host.dispose();
				if ( GameClient.inst != null ) GameClient.inst.gc();
			} catch( e : Dynamic ) {
				trace( "error occured while disposing: " + e );
			}
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
					infoFlow.getProperties( mainMenuBut ).verticalAlign = Bottom;

					trace( "Failed to connect to server" );
				}
				return;
			}
			if ( infoFlow != null )
				infoFlow.remove();

			trace( "Connected to server", uid );

			sendMessage( Message.ClientInit( uid ) );

			onConnection.dispatch();
		} );
		@:privateAccess
		host.socket.onError = onError;

		host.onMessage = ( c, msg : Message ) -> {
			switch( msg ) {
				case WorldInfo( seed ):
					this.seed = seed;
				default:
			}
		}

		host.onUnregister = function ( o ) {
			if ( Std.isOfType( o, Entity ) ) cast( o, Entity ).destroy();
		};
	}

	function onError( msg : String ) {
		switch msg {
			case "Connection closed" | "Failed to write data":
				if ( connected ) onConnectionClosed();
			default:
				trace( "socket error: " + msg );
		}
	}

	function onConnectionClosed() {
		GameClient.inst.destroy();
		disconnect();
		Main.inst.root.add( new ConfirmDialog( "Connection closed", ( e ) -> MainMenu.spawn( Boot.inst.s2d ) ).h2dObject, Const.DP_UI );
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
