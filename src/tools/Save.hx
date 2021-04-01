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

typedef CachedEntity = {
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
		// sqlite.request("attach database save/");

		// trace(sqlite.request("select sqlite_version()").next());
	}

	public function fillDbWithScheme(?table : String = "") {
		var standardStr : String;
		File.load("res/save_str.sql", (data) -> {
			standardStr = data.toString();
		});

		for (i in standardStr.split(";")) {
			try {
				sqlite.request(StringTools.replace(StringTools.replace(i, "CREATE TABLE ", 'CREATE TABLE ${table}.'), ";", ""));
			} catch( e:Dynamic ) {
				#if debug
				trace(e);
				#end
			}
		}
		// sqlite.request("PRAGMA journal_mode = WAL");
		// sqlite.request("PRAGMA read_uncommitted=1");
	}

	public function makeFreshSave(fileName : String) {
		sqlite.request('attach ${sqlite.quote(SAVEPATH + fileName + Const.SAVEFILE_EXT)} as new');
		fillDbWithScheme("new");
		sqlite.request("detach 'new'");
		trace("making new");
	}

	public function getLevelByName(name : String) : CachedLevel {
		var query = sqlite.request('select * from maindb.rooms where name=${name}');
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

	function reattachMainFrom(file : String) {
		try sqlite.rollback() catch( e:Dynamic )
			#if debug
			trace(e);
			#end
		try sqlite.request("detach maindb") catch( e:Dynamic )
			#if debug
			trace(e);
			#end

		sqlite.request('attach database ${sqlite.quote(SAVEPATH + file + Const.SAVEFILE_EXT)} as maindb');
	}

	public function saveGame(fileName : String) {
		if ( currentFile != null ) {
			if ( currentFile != fileName ) {
				// целевой файл бекапится, а потом удаляется
				bakSave(fileName);
				File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT);
				// сохраняем копию текущего несохранённого файла, чтобы потом подменить
				sys.io.File.copy(filePath, SAVEPATH + fileName + Const.SAVEFILE_EXT);
				try sqlite.commit() catch( e:Dynamic ) {}
				swapFiles(filePath, SAVEPATH + fileName + Const.SAVEFILE_EXT);
				reattachMainFrom(fileName);
				sqlite.startTransaction();
			}
		} else {
			// try sqlite.rollback() catch( e:Dynamic ) {}
			reattachMainFrom(fileName);
			sqlite.startTransaction();
		}
		saveLevel(Level.inst);
		sqlite.commit();
		sqlite.request("PRAGMA foreign_keys=on");
		currentFile = fileName;
		sqlite.startTransaction();
	}

	public function saveLevel(level : Level) {
		// single-player only, exclude with compiler flag in multiplayer
		sqlite.request('delete from maindb.rooms where name=${sqlite.quote(level.lvlName)}');
		sqlite.request("delete from maindb.entities where name like '%.Player'");

		level.data.layers.remove(level.getLayerByName('entities'));

		sqlite.request('insert into maindb.rooms (name, tmx) values(
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

		sqlite.request('insert into maindb.entities (name, blob, level_id) values(
			${sqlite.quote(Std.string(entity))},
			${sqlite.quote(Base64.encode(bytes))},
			${entity.level.sqlId}
		)');
	}

	// only singleplayer or server-side
	public function loadGame(fileName : String) {
		try sqlite.rollback()
		catch( e:Dynamic ) {}

		if ( fileName != currentFile ) reattachMainFrom(fileName);
		Main.inst.startGame();

		Main.inst.delayer.addF(() -> {
			// singleplayer player select
			var playerEntry = sqlite.request('select * from maindb.entities where name=${sqlite.quote("en.player.Player")}');
			if ( playerEntry.length > 1 ) throw "save system malfunction, more than one player entries in single player mode";
			var temp = sqlite.request('select id ${sqlite.quote('sqlId')}, * from maindb.rooms where id = ${playerEntry.next().level_id}').next();

			loadLevel(temp);
			sqlite.request("PRAGMA foreign_keys=on");
			sqlite.startTransaction();
			currentFile = fileName;
		}, 2);
	}

	public function loadLevel(level : CachedLevel) {
		Game.inst.startLevelFromParsedTmx(Unserializer.run(Base64.decode(level.tmx).toString()), level.name).sqlId = Std.int(level.sqlId);

		var entities = sqlite.request('select * from maindb.entities where level_id = ${level.sqlId}');
		if ( entities.hasNext() ) for (i in entities) loadEntity(i);

		Game.inst.player = Player.inst;
		Game.inst.targetCameraOnPlayer();
	}

	public function loadEntity(entity : CachedEntity) {
		var u = new Serializer();
		var ent = cast(u.unserialize(Base64.decode(entity.blob), Type.resolveClass(entity.name)), Entity);
	}
}
