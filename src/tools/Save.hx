package tools;

import hxbit.Serializer;
import en.player.Player;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import en.structures.Chest;
import sys.db.ResultSet;
import hxd.File;
import sys.db.Connection;
import sys.db.Sqlite;

class Save {
	public static var inst : Save;

	public var sqliteI : Connection;

	public function new(saveFile : String) {
		inst = this;
		sys.thread.Thread.create(() -> {
			var filePath = saveFile + ".zhopa";

			sqliteI = Sqlite.open(filePath);

			// sqliteI.request('INSERT INTO entities (id, name) VALUES(1, "hui")');

			// Initializing fresh new save
			var standardStr : String;
			File.load("res/save_str.sql", (data) -> {
				standardStr = data.toString();
			});

			for (i in standardStr.split(";")) {
				try {
					sqliteI.request(StringTools.replace(i, ";", ""));
				}
				catch( e:Dynamic ) {
					#if debug
					trace("error: " + e);
					#end
				}
			}
		});
	}

	public function saveGame() {
		var entClone = Entity.ALL.copy();

		for (i in entClone) {
			saveEntity(i);
		}
	}

	public function saveLevel(level : Level) {}

	public function saveEntity(entity : Entity) {
		var s = new hxbit.Serializer();
		var bytes = s.serialize(entity);

		request('INSERT INTO ENTITIES (id, name, blob) VALUES(
		${sqliteI.lastInsertId() + 1},
		${sqliteI.quote(Std.string(entity))},
		${sqliteI.quote(Base64.encode(bytes))}
		)');
	}

	// only singleplayer or server-side
	public function loadGame(requestResult : ResultSet) {
		Main.inst.startGame();
	}

	public function loadEntity(requestResult : ResultSet) {}

	// public function load() {}

	function request(command : String) : ResultSet {
		var result;
		// sys.thread.Thread.create(() -> {
		result = sqliteI.request(command);
		// }).;
		return result;
	}
}
