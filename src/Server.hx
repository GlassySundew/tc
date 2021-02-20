import Message.PlayerInit;
import Message.MapLoad;
import Message.MessageType;
import h2d.Scene;
import en.player.Player;
import h3d.Engine;
import hxd.System;
import dn.Process;
import hxd.net.Socket;
import hxbit.NetworkHost;
import hxd.net.SocketHost;

using Server.SocketHostExtender;

class Server extends Process {
	static var parsedPort = Std.parseInt(Sys.getEnv("PORT"));
	static var PORT : Int = parsedPort != null ? parsedPort : 6676;
	static var HOST = "0.0.0.0";

	public var host : SocketHost;
	public var event : hxd.WaitEvent;
	public var uid : Int;

	public static var game : GameServer;
	public static var inst : Server;

	var isDisposed : Bool;

	static public function main() : Void {
		inst = new Server();
	}

	public function new() {
		super();

		isDisposed = false;
		hxd.System.start(function() {
			setup();
		});
	}

	function setup() {
		loadAssets(function() {
			mainLoop();
			hxd.System.setLoop(mainLoop);

			startServer();

			@:privateAccess new h3d.Engine();
			engine.init();

			entParent = new Scene();

			if ( GameServer.inst != null ) {
				GameServer.inst.destroy();
				game = new GameServer();
			} else
				game = new GameServer();
		});
	}

	function mainLoop() {
		hxd.Timer.update();
		if ( isDisposed ) return;
		updateFixed(hxd.Timer.dt);
		if ( isDisposed ) return;
	}

	function startServer() {
		event = new hxd.WaitEvent();
		host = new hxd.net.SocketHost();
		host.setLogger(function(msg) log(msg));

		@:privateAccess host.waitFixed(HOST, PORT, function(c) {
			log("Client Connected");
		}, function(c : SocketClient) {
			try {
				// cast(c.ownerObject, Cursor).dispose();
				host.unregister(c.ownerObject);
			}
			catch( e:Dynamic ) {}
		});

		host.onTypedMessage((c, msg : Message) -> {
			switch( msg.type ) {
				case playerInit:
					var uid : Int = cast(msg, PlayerInit).uid;
					log("Client identified (" + uid + "nickname: " + cast(msg, PlayerInit).nickname + ")");
					var cursorClient = new Player(GameServer.inst.tmxMap.properties.getFloat("playerX"),
						GameServer.inst.tmxMap.properties.getFloat("playerY"), uid, cast(msg, PlayerInit).nickname);
					// game.applyTmxObjOnEnt(cursorClient);
					host.sendMessage(new MapLoad(GameServer.inst.lvlName, GameServer.inst.tmxMap), c);
					c.ownerObject = cursorClient;
					c.sync();

				// cursorClient.footX = 2448;
				// cursorClient.footY = 1933;
				default:
			}
		});
		host.onUnregister = function(c) {
			log('unregistered ' + c);
		}

		log("Server Started");
		host.makeAlive();
		host.flush();
	}

	@:dox(show)
	function loadAssets(onLoaded : Void -> Void) {
		onLoaded();
	}

	public function log(s : String, ?pos : haxe.PosInfos) {
		pos.fileName = (host.isAuth ? "[S]" : "[C]") + " " + pos.fileName;
		haxe.Log.trace(s, pos);
	}

	var speed = 1.0;

	@:dox(show)
	function updateFixed(dt : Float) {
		super.update();
		var tmod = hxd.Timer.tmod * speed;
		dn.Process.updateAll(tmod);
		if ( host != null ) host.flush();
	}

	function dispose() {
		isDisposed = true;
	}
}

class SocketHostExtender {
	static public function waitFixed(sHost : SocketHost, host : String, port : Int, ?onConnected : NetworkClient -> Void,
			?onError : SocketClient -> Void) @:privateAccess {
		sHost.close();
		sHost.isAuth = false;
		sHost.socket = new Socket();
		sHost.self = new SocketClient(sHost, null);
		sHost.socket.bind(host, port, function(s) {
			var c = new SocketClient(sHost, s);
			sHost.pendingClients.push(c);
			s.onError = function(_) {
				if ( onError != null ) onError(c);
				c.stop();
			}
			if ( onConnected != null ) onConnected(c);
		});
		sHost.isAuth = true;
	}
}
