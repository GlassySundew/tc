package tools;

import sys.FileSystem;
import hl.uv.Stream;
import haxe.ds.Map;
import haxe.io.Bytes;
import en.player.Player;
import haxe.Unserializer;
import haxe.crypto.Base64;
import hxbit.Serializer;
import hxd.File;
import sys.db.Connection;
import sys.db.ResultSet;
import sys.db.Sqlite;

typedef CachedLevel = {
	public var name : String;
	public var tmx : String;
	public var sqlId : Int;
}

class CachedEntity {
	// basically just a class name, i.e. en.player.Player
	public var name : String;
	public var blob : String;
	public var level_id : Null<Int>;
}

class Save {
	public static var inst : Save;

	public var sqlite : Connection;
	public var filePath(get, never) : String;

	function get_filePath() {
		return SAVEPATH + currentFile + Const.SAVEFILE_EXT;
	}

	public var currentFile : String;

	public function new() {
		inst = this;

		sqlite = Sqlite.open("");
		// trace(sqlite.request("select sqlite_version()").next());
	}

	public static function fillDbWithScheme(sqlite : Connection, ?table : String) {
		var standardStr : String;
		File.load("res/save_str.sql", (data) -> {
			standardStr = data.toString();
		});

		for (i in standardStr.split(";")) {
			try {
				sqlite.request(StringTools.replace(i, ";", ""));
			}
			catch( e:Dynamic ) {
				#if debug
				trace(e);
				#end
			}
		}
		sqlite.request("PRAGMA journal_mode = WAL");
		sqlite.request("PRAGMA read_uncommitted=1");
	}

	public function makeFreshSave(fileName : String) {
		var tempCon = Sqlite.open(SAVEPATH + fileName + Const.SAVEFILE_EXT);
		tools.Save.fillDbWithScheme(tempCon);
		tempCon.close();
	}

	public function getLevelByName(name : String) : CachedLevel {
		var query = sqlite.request('select * from rooms where name=${name}');
		return query.hasNext() ? query.next() : null;
	}

	public function bakSave(fileName : String) {
		// deleting old bak
		if ( File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak") ) File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak");
		sys.io.File.copy(SAVEPATH + fileName + Const.SAVEFILE_EXT, SAVEPATH + fileName + Const.SAVEFILE_EXT + '.bak');
	}

	public function swapFiles(file1 : String, file2 : String) {
		FileSystem.rename(file1, file1 + ".swap");
		sys.io.File.copy(file2, file1);
		FileSystem.rename(file1 + ".swap", file2);
	}

	public function saveGame(fileName : String) {
		if ( currentFile != null ) {
			if ( currentFile != fileName ) {
				// целевой файл бекапится, а потом удаляется
				bakSave(fileName);
				File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT);
				// сохраняем копию текущего несохранённого файла, чтобы потом подменить
				sys.io.File.copy(filePath, SAVEPATH + fileName + Const.SAVEFILE_EXT);
				sqlite.commit();
				swapFiles(filePath, SAVEPATH + fileName + Const.SAVEFILE_EXT);
				sqlite.close();
				sqlite = Sqlite.open(SAVEPATH + fileName + Const.SAVEFILE_EXT);
			}
		} else {
			trace("nulling");
			
			sqlite.close();
			sqlite = Sqlite.open(SAVEPATH + fileName + Const.SAVEFILE_EXT);
			sqlite.startTransaction();
		}
		saveLevel(Level.inst);
		sqlite.commit();

		currentFile = fileName;
		sqlite.startTransaction();
	}

	public function saveLevel(level : Level) {
		// single-player only, exclude with compiler flag in multiplayer
		sqlite.request("delete from entities where name like '%.Player'");
		sqlite.request('delete from rooms where name=${sqlite.quote(level.lvlName)}');

		sqlite.request('insert into rooms (name, tmx) values(
			${sqlite.quote(level.lvlName)},
			${sqlite.quote(Base64.encode(Bytes.ofString(haxe.Serializer.run(level.data))))}
		)');
		level.sqlId = sqlite.lastInsertId();

		for (i in Entity.ALL) {
			if ( i.level.sqlId == level.sqlId ) {
				saveEntity(i);
			}
		}
	}

	// push cached entity into disk-file
	public function saveEntity(entity : Entity) {
		var s = new hxbit.Serializer();
		var bytes = s.serialize(entity);

		sqlite.request('insert into entities (name, blob, level_id) values(
			${sqlite.quote(Std.string(entity))},
			${sqlite.quote(Base64.encode(bytes))},
			${entity.level.sqlId}
		)');
	}

	function dropAll() {
		// sqlite.request("PRAGMA writable_schema = 1");
		// sqlite.request("delete from :memory: where type in ('table', 'index', 'trigger')");
		// sqlite.request("PRAGMA writable_schema = 0");
		// sqlite.request("vacuum");
		// sqlite.request("pragma integrity_check");
		sqlite.close();
	}

	// only singleplayer or server-side
	public function loadGame(fileName : String) {
		try
			sqlite.rollback()
		catch( e:Dynamic ) {}

		sqlite.close();
		sqlite = Sqlite.open(SAVEPATH + fileName + Const.SAVEFILE_EXT);

		Main.inst.startGame();

		Main.inst.delayer.addF(() -> {
			// singleplayer player select
			var playerEntry = sqlite.request('select * from entities where name=${sqlite.quote("en.player.Player")}');
			if ( playerEntry.length > 1 ) throw "save system malfunction, more than one player entries in single player mode";
			loadLevel(sqlite.request('select * from rooms where id = ${playerEntry.next().level_id}').next());
			sqlite.startTransaction();
			currentFile = fileName;
		}, 2);
	}

	public function loadLevel(level : CachedLevel) {
		Game.inst.startLevelFromParsedTmx(Unserializer.run(Base64.decode(level.tmx).toString()), level.name);
		var entities = sqlite.request('select * from entities where level_id = ${level.sqlId}');
		if ( entities.hasNext() ) for (i in entities) loadEntity(i);

		Game.inst.player = Player.inst;
		Game.inst.targetCameraOnPlayer();
	}

	public function loadEntity(entity : CachedEntity) {
		var u = new Serializer();
		var ent = cast(u.unserialize(Base64.decode(entity.blob), Type.resolveClass(entity.name)), Entity);
	}
}
