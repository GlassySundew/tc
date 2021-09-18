package tools;

import hx.concurrent.executor.Executor;
import haxe.crypto.Base64;
import en.player.Player;
import haxe.Unserializer;
import haxe.io.Bytes;
import hxbit.Serializer;
import hxd.File;
import hxd.Res;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.Sqlite;

typedef CachedLevel = {
	public var id : Int;
	public var name : String;
	public var tmx : String;
}

typedef CachedEntity = {
	public var id : Int;
	/** basically just a class name, i.e. 'en.player.Player' **/
	public var name : String;
	public var blob : String;
	public var level_id : Null<Int>;
}
/** for proper work .hdll libs of sqlite of the latest version need to be compiled(amalgamation) and also with URI enabled **/
class Save {
	public static var inst : Save;

	public var sqlite : Connection;
	public var currentFilePath(get, never) : String;
	public var transacting : Bool = false;

	function get_currentFilePath() {
		return SAVEPATH + currentFile + Const.SAVEFILE_EXT;
	}

	public var currentFile : String;

	public function new() {
		inst = this;

		sqlite = Sqlite.open("");
		sqlite.request("attach database 'file::memory:' as maindb");
		fillDbWithScheme(sqlite, "maindb");
		startTransaction();
	}

	public function startTransaction() {
		if ( !transacting ) try {
			sqlite.startTransaction();
			transacting = true;
			#if sqlite_debug_verbose
			trace("starting transaction from line " + switch CallStack.callStack()[1] {
				case FilePos(s, file, line):
					Std.string(line);
				default:
					"";
			});
			#end
		} catch( e:Dynamic ) {
			trace(e);
		}
	}

	public function commitChanges() {
		if ( transacting ) try {
			sqlite.commit();
			transacting = false;
			#if sqlite_debug_verbose
			trace("commiting changes from line " + switch CallStack.callStack()[1] {
				case FilePos(s, file, line):
					Std.string(line);
				default:
					"";
			});
			#end
		} catch( e:Dynamic ) {
			trace(e);
		}
	}

	public function rollbackChanges() {
		if ( transacting ) try {
			sqlite.rollback();
			transacting = false;
			#if sqlite_debug_verbose
			trace("rollbacking changes from line " + switch CallStack.callStack()[1] {
				case FilePos(s, file, line):
					Std.string(line);
				default:
					"";
			});
			#end
		} catch( e:Dynamic ) {
			trace(e);
		}
	}

	public function disconnect() {
		try {
			rollbackChanges();
			sqlite.request("detach maindb");
		} catch( e:Dynamic ) {
			#if debug
			trace("error on detach: " + e);
			#end
		}
	}

	public function isDbLocatedInMemory( db : String ) : Bool {
		for ( i in sqlite.request("PRAGMA database_list") ) {
			if ( i.name == db && i.file == "" ) return true;
		}
		return false;
	}

	public function isMainDbAttached() : Bool {
		var connectedDbS = sqlite.request("PRAGMA database_list");
		for ( i in connectedDbS ) {
			if ( i.name == "maindb" ) return true;
		}
		return false;
	}

	public static function fillDbWithScheme( sqlite : Connection, ?table : String = "" ) {
		var standardStr = Res.save_str_sql.entry.getText();

		for ( i in standardStr.split(";") ) {
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

	public function makeFreshSave( fileName : String ) {
		if ( isDbLocatedInMemory("maindb") ) {
			try {
				sqlite.request("detach maindb");
			} catch( e:Dynamic ) {
				#if debug
				trace("error on detach: " + e);
				#end
			}
		}

		var sqliteNew = Sqlite.open("");
		sqliteNew.request('attach ${sqliteNew.quote(SAVEPATH + fileName + Const.SAVEFILE_EXT)} as new');
		fillDbWithScheme(sqliteNew, "new");
		sqliteNew.close();

		sqlite.close();
		sqlite = Sqlite.open(fileName);

		reattachMainFrom(fileName);
	}

	public function bakSave( fileName : String ) {
		// deleting old bak
		if ( File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak") ) File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak");

		var executor = Executor.create(1);
		var task = () -> {
			var i = 0;
			while( !File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT) ) {
				haxe.Timer.delay(() -> i++, 200);
				if ( i > 10 ) return;
			};
			sys.io.File.copy(SAVEPATH + fileName + Const.SAVEFILE_EXT, SAVEPATH + fileName + Const.SAVEFILE_EXT + '.bak');
		}
		executor.submit(task, ONCE(0));
	}

	public function swapFiles( file1 : String, file2 : String ) {
		if ( File.exists(file1) && File.exists(file2) ) {
			FileSystem.rename(file1, file1 + ".swap");
			sys.io.File.copy(file2, file1);
			FileSystem.rename(file1 + ".swap", file2);
		} else
			throw "file(s) do not exist";
	}

	function reattachMainFrom( file : String ) {
		rollbackChanges();

		try sqlite.request("detach maindb") catch( e:Dynamic ) {
			#if debug
			trace("error on detach: " + e);
			#end
		}

		sqlite.request('attach database ${sqlite.quote(SAVEPATH + file + Const.SAVEFILE_EXT)} as maindb');
	}

	public function saveGame( fileName : String ) {
		var targetFilePath = SAVEPATH + fileName + Const.SAVEFILE_EXT;
		if ( isDbLocatedInMemory("maindb") ) {
			// debug scenario when entry point was not in main menu
			// backing target file
			if ( File.exists(targetFilePath) ) {
				bakSave(fileName);
				File.delete(targetFilePath);
			}
			saveLevel(Level.inst);
			commitChanges();
			sqlite.request('vacuum maindb into ${sqlite.quote(targetFilePath)}');
			startTransaction();
		} else if ( currentFile != null && currentFile == fileName ) {
			// saving in the same file as previous time
			// целевой файл бекапится, а потом удаляется
			bakSave(fileName);
			File.delete(targetFilePath);
			// сохраняем копию текущего несохранённого файла, чтобы потом подменить
			sys.io.File.copy(currentFilePath, targetFilePath);
			try sqlite.commit() catch( e:Dynamic ) {}
			swapFiles(currentFilePath, targetFilePath);
			reattachMainFrom(fileName);
			startTransaction();
		} else {
			// saving to new file
			reattachMainFrom(fileName);
			startTransaction();
		}

		saveLevel(Level.inst);
		commitChanges();
		sqlite.request("PRAGMA foreign_keys=on");
		currentFile = fileName;
		startTransaction();
	}

	public function saveLevel( level : Level ) : CachedLevel {
		// checking if maindb attached
		if ( isMainDbAttached() ) {
			// single-player only, exclude with compiler flag in multiplayer
			// sqlite.request("delete from maindb.entities where name like '%.Player'");

			// dropping "entities" tmx layer in favor of previously saved layer
			var entitiesTmxLayer = level.getLayerByName('entities');
			if ( entitiesTmxLayer != null ) level.data.layers.remove(entitiesTmxLayer);

			var levelBlob = sqlite.quote(Base64.encode(Bytes.ofString(haxe.Serializer.run(level.data))));
			if ( sqlite.request('select * from maindb.rooms where name = ${sqlite.quote(level.lvlName)}').hasNext() ) {
				sqlite.request('update maindb.rooms set 
				name = ${sqlite.quote(level.lvlName)}, 
				tmx = ${levelBlob}
				where name = ${sqlite.quote(level.lvlName)}
			');
			} else {
				sqlite.request('insert into maindb.rooms (name, tmx) values(
				${sqlite.quote(level.lvlName)},
				${levelBlob}
			)');
			}

			// requesting our newly updated/inserted room to assign sql id to it's instance
			var cachedLevel : CachedLevel = sqlite.request('select id "sqlId", * from maindb.rooms where name = ${sqlite.quote(level.lvlName)}').next();

			level.sqlId = cachedLevel.id;

			for ( i in Entity.ALL ) {
				if ( i.level.sqlId == level.sqlId ) {
					saveEntity(i);
				}
			}
			return cachedLevel;
		}
		return null;
	}

	public function saveEntity( entity : Entity ) {
		var s = new hxbit.Serializer();
		var bytes = s.serialize(entity);

		if ( Std.isOfType(entity, Player) && isPlayerSaved() ) {
			sqlite.request('update maindb.entities set
				name = ${sqlite.quote(Std.string(entity))},
				blob = ${sqlite.quote(Base64.encode(bytes))},
				level_id = ${entity.level.sqlId}
				where name = "en.player.Player" and id = ${entity.sqlId}
			');
		} else {
			if ( entity.sqlId != null ) {
				sqlite.request('update maindb.entities set
					name = ${sqlite.quote(Std.string(entity))},
					blob = ${sqlite.quote(Base64.encode(bytes))},
					level_id = ${entity.level.sqlId}
					where id = ${entity.sqlId}
				');
			} else {
				sqlite.request('insert into maindb.entities (name, blob, level_id) values(
					${sqlite.quote(Std.string(entity))},
					${sqlite.quote(Base64.encode(bytes))},
					${entity.level.sqlId}
				)');
				entity.sqlId = sqlite.request('select max(id) id from maindb.entities').next().id;
			}
		}
		// entity.sqlId =
	}

	// only singleplayer or server-side
	public function loadGame( fileName : String ) {
		rollbackChanges();
		if ( fileName != currentFile ) reattachMainFrom(fileName);
		sqlite.request("PRAGMA foreign_keys=on");
		startTransaction();
		Main.inst.startGame();

		Main.inst.delayer.addF(() -> {
			// singleplayer player level load
			rollbackChanges();
			startTransaction();

			loadLevelWithPlayerSingle();
			currentFile = fileName;
		}, 3);
	}

	// Search for a room where player is saved in and loads it
	public function loadLevelWithPlayerSingle() {
		var playerEntry = sqlite.request('select * from maindb.entities where name = "en.player.Player"');
		if ( playerEntry.length > 1 ) throw "save system malfunction, more than one player entries in single player mode";
		var temp = sqlite.request('select * from maindb.rooms where id = ${playerEntry.next().level_id}').next();

		loadLevel(temp);
	}

	public function loadLevel( level : CachedLevel ) : Level {
		sqlite.request('update maindb.entities set level_id = ${level.id} where name = "en.player.Player"');
		var loadedLevel = Game.inst.startLevelFromParsedTmx(Unserializer.run(Base64.decode(level.tmx).toString()), level.name);
		loadedLevel.sqlId = Std.int(level.id);

		var entities = sqlite.request('select * from maindb.entities where level_id = ${level.id}');

		if ( entities.hasNext() ) for ( i in entities ) loadEntity(i);

		Game.inst.player = Player.inst;
		Game.inst.targetCameraOnPlayer();

		return loadedLevel;
	}

	public function getLevelByName( name : String ) {
		var query = sqlite.request('select * from maindb.rooms where name = ${sqlite.quote(name)}');
		return query.hasNext() ? query.next() : null;
	}

	public function loadLevelByName( name : String ) : Level {
		try {
			var levelToBeLoaded = getLevelByName(name);
			if ( levelToBeLoaded != null ) {
				// переносим игрока в новую локацию
				var loadedLevel = loadLevel(levelToBeLoaded);

				return loadedLevel;
			} else {
				return null;
			}
		} catch( e:Dynamic ) {
			trace(e);
			return null;
		}
	}

	public function isPlayerSaved() : Bool {
		return sqlite.request('select * from maindb.entities where name = "en.player.Player"').hasNext();
	}

	// used to load saved player to new-loaded .tmx locations
	public function bringPlayerToLevel( level : CachedLevel ) {
		sqlite.request('update maindb.entities set level_id = ${level.id} where name = "en.player.Player"');
	}

	public function playerSavedOn( level : Level ) {
		return sqlite.request('select * from maindb.entities where name = "en.player.Player" and level_id = ${level.sqlId}').next();
	}
	/**basically a fix for entity duplicates when disposing**/
	public function removeEntityById( id : Int ) {
		sqlite.request('delete from maindb.entities where id=$id');
	}

	public function loadEntity( entity : CachedEntity ) {
		try {
			var u = new Serializer();
			var ent = cast(u.unserialize(Base64.decode(entity.blob), Type.resolveClass(entity.name)), Entity);
			ent.sqlId = entity.id;
		} catch( e:Dynamic ) {
			trace("error while unserializing entity: " + e, haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		}
	}
}
