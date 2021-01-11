// package net;

// import ui.Console;
// import h3d.mat.Texture;
// import en.player.WebPlayer;
// import io.colyseus.serializer.schema.Schema;
// import io.colyseus.Client;
// import io.colyseus.Room;

// class Connect {
// 	public static var inst:Connect;

// 	var playerI(get, never):en.player.Player;

// 	inline function get_playerI()
// 		return en.player.Player.inst;

// 	// @:forward(listen, onJoin, onStateChange, onMessage, send)
// 	public var room:Room<State>;

// 	private var client:Client;
// 	private var webPlayers:Map<String, Entity> = new Map();

// 	public function new() {
// 		inst = this;
// 		// this.client = new Client('ws://0.0.0.0:8080');
// 		this.client = new Client("wss://testgovno.herokuapp.com");
// 		haxe.Timer.delay(function() {
// 			this.client.getAvailableRooms("my_room", function(err, rooms) {
// 				if (err != null) {
// 					trace("ERROR! " + err);
// 					return;
// 				}

// 				for (room in rooms) {
// 					trace("RoomAvailable:");
// 					trace("roomId: " + room.roomId);
// 					trace("clients: " + room.clients);
// 					trace("maxClients: " + room.maxClients);
// 					trace("metadata: " + room.metadata);
// 				}
// 			});
// 		}, 3000);
// 		this.client.joinOrCreate("my_room", [], State, function(err, room) {
// 			if (err != null) {
// 				haxe.Timer.delay(function() {
// 					trace("NETWORK ERROR: " + err);
// 				}, 0); 
// 			}
// 			this.room = room;

// 			this.room.onJoin += function() {
// 				Console.inst.log('CONNECTION TO ${this.client.endpoint} SUCCESSFULL', 0x5d9047);
// 				playerI.sendPosToServer();
// 			};

// 			this.room.state.players.onAdd = function(player, key) {
// 				// добавляем всех игроков, которые сейчас на сервере 
// 				if (this.room.sessionId != key /*&& playerI.netId != null*/) {
// 					haxe.Timer.delay(function() {
// 						trace("PLAYER ADDED AT: ", key, "SESSION : " + room.sessionId);
// 						var webPlayer = new WebPlayer(0, 0);
// 						webPlayer.footX = player.x;
// 						webPlayer.footY = player.y;
// 						webPlayers[key] = webPlayer;
// 					}, 0);
// 				}
// 			}

// 			this.room.state.players.onChange = function(player, key) {
// 				haxe.Timer.delay(function() {
// 					trace("PLAYER CHANGED AT: ", key, playerToString(player));
// 				}, 0);

// 				if (this.room.state.players.length > 1 && key != room.sessionId) {
// 					webPlayers[key].footX = player.x;
// 					webPlayers[key].footY = player.y;
// 				}
// 			}

// 			this.room.state.players.onRemove = function(player, key) {
// 				haxe.Timer.delay(function() {
// 					trace("PLAYER REMOVED AT: ", key);
// 					webPlayers[key].dispose();
// 				}, 0);
// 			}

// 			this.room.onStateChange += function(state:State) {
// 				haxe.Timer.delay(function() {
// 					trace("STATE CHANGE: " + Std.string(state));
// 				}, 0);
// 			};

// 			this.room.onMessage(0, function(message) {
// 				haxe.Timer.delay(function() {
// 					trace("onMessage: 0 => " + message);
// 				}, 0);
// 			});

// 			this.room.onMessage("type", function(message) {
// 				haxe.Timer.delay(function() {
// 					trace("onMessage: 'type' => " + message);
// 				}, 0);
// 			});

// 			this.room.onError += function(code:Int, message:String) {
// 				haxe.Timer.delay(function() {}, 0);
// 				trace("ROOM ERROR: " + code + " => " + message);
// 			};

// 			this.room.onLeave += function() {
// 				haxe.Timer.delay(function() {
// 					trace("ROOM LEAVE");
// 				}, 0);
// 			}
// 		});
// 	}

// 	inline function playerToString(player:Player):String
// 		return 'x = ${player.x}, y = ${player.y}';
// }
