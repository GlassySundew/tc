package tools;

import dn.Process;
import haxe.CallStack;
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
		#if debug
		sqlite.request("attach database 'file::memory:' as maindb");
		fillDbWithScheme(sqlite, "maindb");
		startTransaction();
		#end
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
		var schemaStringDump = Res.save_schema_sql.entry.getText();

		for ( i in schemaStringDump.split(";") ) {
			try {
				sqlite.request(StringTools.replace(StringTools.replace(i, "CREATE TABLE ", 'CREATE TABLE ${table}.'), ";", ""));
			} catch( e:Dynamic ) {
				#if debug
				trace(e);
				#end
			}
		}
		sqlite.request("PRAGMA journal_mode = memory");
		sqlite.request("PRAGMA read_uncommitted=1");
	}

	public function makeFreshSave( fileName : String ) {
		if ( File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT) ) {
			File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT);
		}

		if ( sqlite != null && isDbLocatedInMemory("maindb") ) {
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

		if ( sqlite != null ) sqlite.close();
		sqlite = Sqlite.open(SAVEPATH + fileName + Const.SAVEFILE_EXT);
		transacting = false;
		sqlite.request("PRAGMA journal_mode = memory");
		sqlite.request("PRAGMA read_uncommitted=1");
		reattachMainFrom(fileName);
	}

	public function bakSave( fileName : String ) {
		// deleting old bak
		if ( File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak") ) File.delete(SAVEPATH + fileName + Const.SAVEFILE_EXT + ".bak");

		var executor = Executor.create(1);
		var i = 0;
		var task = () -> {
			i++;
			if ( i > 10 ) return;

			if ( File.exists(SAVEPATH + fileName + Const.SAVEFILE_EXT) ) {
				sys.io.File.copy(SAVEPATH + fileName + Const.SAVEFILE_EXT, SAVEPATH + fileName + Const.SAVEFILE_EXT + '.bak');
				executor.stop();
			}
		};
		executor.submit(task, FIXED_RATE(100));
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
			// debug scenario when entry point was not in main menu(i. e. scripted level start)
			if ( File.exists(targetFilePath) ) {
				bakSave(fileName);
				File.delete(targetFilePath);
			}
			saveLevel(Level.inst);
			commitChanges();
			sqlite.request('vacuum maindb into ${sqlite.quote(targetFilePath)}');
			startTransaction();
		} else if ( currentFile != null && currentFile != fileName ) {
			// saving into other file

			// rollbackChanges();
			// целевой файл бекапится, а потом удаляется
			if ( File.exists(targetFilePath) ) {
				bakSave(fileName);
				File.delete(targetFilePath);
			}

			// нам нужно, чтобы в текущем файле не сохранились изменения, поэтому мы сохраняем его копию (.swap),
			// чтобы сохранить изменения и поменять сохранённый файл на тот, в который мы хотим сохраниться, затем первый файл вернуть в прежнее состояние
			sys.io.File.copy(currentFilePath, currentFilePath + ".swap");

			saveLevel(Level.inst);
			commitChanges();

			sys.io.File.copy(currentFilePath, targetFilePath);

			File.delete(currentFilePath);

			FileSystem.rename(currentFilePath + ".swap", currentFilePath);

			reattachMainFrom(fileName);
			startTransaction();
		} else {
			// saving to the same file
			reattachMainFrom(fileName);
			startTransaction();
		}

		saveLevel(Level.inst);

		// saving general game data, such as celestial map
		var s = new hxbit.Serializer();
		var bytes = s.serialize(Game.inst);

		sqlite.request('insert into maindb.game (blob) values(
            ${sqlite.quote(Base64.encode(bytes))}
        )');

		commitChanges();

		sqlite.request("PRAGMA foreign_keys=on");
		currentFile = fileName;
		startTransaction();
	}

	public function saveLevel( level : Level ) : CachedLevel {
		// checking if maindb attached
		if ( isMainDbAttached() ) {
			// dropping "entities" tmx layer in favor of previously saved layer
			var tmxMap : format.tmx.Data.TmxMap = Unserializer.run(haxe.Serializer.run(level.data));
			var entitiesTmxLayer = tmxMap.getLayersByName('entities');
			if ( entitiesTmxLayer != null ) tmxMap.layers.remove(entitiesTmxLayer[0]);

			var cachedLevel = upsertLevelMap(level.lvlName, tmxMap);

			// requesting our newly updated/inserted room to assign sql id to it's instance
			// if ( cachedLevel != null )
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

	public function upsertLevelMap( name : String, tmxMap : format.tmx.Data.TmxMap ) : CachedLevel {
		var levelBlob = sqlite.quote(Base64.encode(Bytes.ofString(haxe.Serializer.run(tmxMap))));
		var query = sqlite.request('
		insert into maindb.rooms (name, tmx) values(
			${sqlite.quote(name)},
			${levelBlob}
		) 
		on conflict(name) do update set 
			name = ${sqlite.quote(name)}, 
			tmx = ${levelBlob} 
			where 
				name = ${sqlite.quote(name)}
		 returning *
		').next();

		return query;
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
		} else if ( entity.sqlId != null ) {
			// this entity has been previously saved and is bling updated to db
			sqlite.request('update maindb.entities set
					name = ${sqlite.quote(Std.string(entity))},
					blob = ${sqlite.quote(Base64.encode(bytes))},
					level_id = ${entity.level.sqlId}
					where id = ${entity.sqlId}
				');
		} else {
			// this entity is freshly created, can be a player if it is fresh
			sqlite.request('insert into maindb.entities (name, blob, level_id) values(
					${sqlite.quote(Std.string(entity))},
					${sqlite.quote(Base64.encode(bytes))},
					${entity.level.sqlId}
				)');
			entity.sqlId = sqlite.request('select max(id) id from maindb.entities').next().id;
		}
	}

	// TODO only singleplayer or server-side
	public function loadGame( fileName : String ) {
		rollbackChanges();

		if ( fileName != currentFile ) reattachMainFrom(fileName);
		startTransaction();

		var savedGame = sqlite.request('select * from maindb.game');

		if ( savedGame.hasNext() ) {
			// we do have some saved game
			if ( Game.inst != null ) {
				Game.inst.destroy();
				@:privateAccess Process._garbageCollector(Process.ROOTS);
			}

			var u = new Serializer();
			u.unserialize(Base64.decode(savedGame.next().blob), Game);
		} else
			Main.inst.startGame();

		// singleplayer player level load
		rollbackChanges();
		startTransaction();

		loadLevelWithPlayerSingle();
		currentFile = fileName;
	}

	// Search for a room where player is saved in and loads it
	public function loadLevelWithPlayerSingle() {
		var playerEntry = sqlite.request('select * from maindb.entities where name = "en.player.Player"');
		if ( playerEntry.length > 1 ) throw "save system malfunction, more than one player entries in single player mode";
		var temp = sqlite.request('select * from maindb.rooms where id = ${playerEntry.next().level_id}').next();
		loadLevel(temp);
	}

	public function loadLevel( level : CachedLevel, ?acceptTmxPlayerCoord : Bool = false ) : Level {
		// bringPlayerToLevel(level);

		var loadedLevel = Game.inst.startLevelFromParsedTmx(Unserializer.run(Base64.decode(level.tmx).toString()), level.name, acceptTmxPlayerCoord);
		loadedLevel.sqlId = Std.int(level.id);

		var entities = sqlite.request('select * from maindb.entities where level_id = ${level.id} and not name = ${sqlite.quote("en.player.Player")}');
		if ( entities.hasNext() ) for ( i in entities ) loadEntity(i);

		// var entities = sqlite.request('select * from maindb.entities where level_id = ${level.id} and name = ${sqlite.quote("en.player.Player")}');
		// if ( entities.hasNext() ) for ( i in entities ) loadEntity(i);

		Game.inst.player = Player.inst;
		Game.inst.targetCameraOnPlayer();

		return loadedLevel;
	}

	public function getLevelByName( name : String ) : CachedLevel {
		var query = sqlite.request('select * from maindb.rooms where name = "${name}"');
		return query.hasNext() ? query.next() : null;
	}

	public function loadLevelByName( name : String, ?acceptTmxPlayerCoord : Bool = false ) : Level {
		try {
			var levelToBeLoaded = getLevelByName(name);
			if ( levelToBeLoaded != null ) {
				// переносим игрока в новую локацию
				var loadedLevel = loadLevel(levelToBeLoaded, acceptTmxPlayerCoord);
				return loadedLevel;
			} else {
				return null;
			}
		} catch( e:Dynamic ) {
			trace(e);
			return null;
		}
	}

	// checks if any player has been previously saved in db, singleplayer - only
	public function isPlayerSaved() : Bool {
		return sqlite.request('select * from maindb.entities where name = "en.player.Player"').hasNext();
	}

	// used to load saved player to new-loaded .tmx locations
	public function bringPlayerToLevel( level : CachedLevel ) {
		return sqlite.request('update maindb.entities set level_id = ${level.id} where name = "en.player.Player" returning *');
	}

	public function playerSavedOn( level : Level ) : CachedEntity {
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
