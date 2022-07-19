package tools;

import dn.Process;
import en.player.Player;
import format.tmx.Data.TmxMap;
import haxe.Unserializer;
import haxe.crypto.Base64;
import hx.concurrent.executor.Executor;
import hxbit.Serializer;
import hxd.File;
import hxd.Res;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.Sqlite;

typedef SavedLevel = {
	public var id : Int;
	public var name : String;
	public var tmx : String;
}

typedef SavedEntity = {
	public var id : Int;

	/** basically just a class name, i.e. 'en.player.Player' **/
	public var name : String;
	public var blob : String;
	public var level_id : Null<Int>;
}

typedef SavedPlayer = SavedEntity & {
	public var nickname : String;
}

/** for proper work .hdll libs sqlite of the latest version has to be compiled(amalgamation) and also with URI enabled **/
class Save {
	public static var inst : Save;

	public var sqlite : Connection;
	public var currentFilePath( get, never ) : String;
	public var transacting : Bool = false;

	public static var saveDirectory : String;

	function get_currentFilePath() {
		return saveDirectory + currentFile + Const.SAVEFILE_EXT;
	}

	public var currentFile : String;

	public static function initFields() {
		saveDirectory = SAVEPATH + "save/";
	}

	public function new() {
		inst = this;

		sqlite = Sqlite.open( "" );
		#if debug
		// sqlite.request( "attach database 'file::memory:' as maindb" );
		// fillDbWithScheme( sqlite, "maindb" );
		// startTransaction();
		#end
	}

	public function startTransaction() {
		if ( !transacting ) try {
			sqlite.startTransaction();
			transacting = true;
			#if sqlite_debug_verbose
			trace( "starting transaction from line " + switch CallStack.callStack()[1] {
				case FilePos( s, file, line ):
					Std.string( line );
				default:
					"";
			} );
			#end
		} catch( e : Dynamic ) {
			trace( e );
		}
	}

	public function commitChanges() {
		if ( transacting ) try {
			sqlite.commit();
			transacting = false;
			#if sqlite_debug_verbose
			trace( "commiting changes from line " + switch CallStack.callStack()[1] {
				case FilePos( s, file, line ):
					Std.string( line );
				default:
					"";
			} );
			#end
		} catch( e : Dynamic ) {
			trace( e );
		}
	}

	public function rollbackChanges() {
		if ( transacting ) try {
			sqlite.rollback();
			transacting = false;
			#if sqlite_debug_verbose
			trace( "rollbacking changes from line " + switch CallStack.callStack()[1] {
				case FilePos( s, file, line ):
					Std.string( line );
				default:
					"";
			} );
			#end
		} catch( e : Dynamic ) {
			trace( e );
		}
	}

	public function disconnect() {
		try {
			rollbackChanges();
			sqlite.request( "detach maindb" );
		} catch( e : Dynamic ) {
			#if debug
			trace( "error on detach: " + e );
			#end
		}
	}

	public function isDbLocatedInMemory( db : String ) : Bool {
		for ( i in sqlite.request( "PRAGMA database_list" ) ) {
			if ( i.name == db && i.file == "" ) return true;
		}
		return false;
	}

	public function isMainDbAttached() : Bool {
		var connectedDbS = sqlite.request( "PRAGMA database_list" );
		for ( i in connectedDbS ) {
			if ( i.name == "maindb" ) return true;
		}
		return false;
	}

	public static function fillDbWithScheme( sqlite : Connection, ?table : String = "" ) {
		var schemaStringDump = Res.save_schema_sql.entry.getText();

		for ( i in schemaStringDump.split( ";" ) ) {
			try {
				sqlite.request( StringTools.replace( StringTools.replace( i, "CREATE TABLE ", 'CREATE TABLE ${table}.' ), ";", "" ) );
			} catch( e : Dynamic ) {
				#if debug
				trace( e );
				#end
			}
		}
		sqlite.request( "PRAGMA journal_mode = memory" );
		sqlite.request( "PRAGMA read_uncommitted=1" );
	}

	public function makeFreshSave( fileName : String ) {
		sys.FileSystem.createDirectory( haxe.io.Path.directory( saveDirectory ) );

		if ( File.exists( saveDirectory + fileName + Const.SAVEFILE_EXT ) ) {
			File.delete( saveDirectory + fileName + Const.SAVEFILE_EXT );
		}

		if ( sqlite != null && isDbLocatedInMemory( "maindb" ) ) {
			commitChanges();
			
			try {
				sqlite.request( "detach maindb" );
			} catch( e : Dynamic ) {
				#if debug
				trace( "error on detach: " + e );
				#end
			}
		}

		var sqliteNew = Sqlite.open( "" );
		sqliteNew.request( 'attach ${sqliteNew.quote( saveDirectory + fileName + Const.SAVEFILE_EXT )} as new' );
		fillDbWithScheme( sqliteNew, "new" );
		sqliteNew.close();

		if ( sqlite != null ) sqlite.close();

		sqlite = Sqlite.open( saveDirectory + fileName + Const.SAVEFILE_EXT );
		transacting = false;
		sqlite.request( "PRAGMA journal_mode = memory" );
		sqlite.request( "PRAGMA read_uncommitted=1" );
		reattachMainFrom( fileName );
	}

	public function bakSave( fileName : String ) {
		// deleting old bak
		if ( File.exists( saveDirectory + fileName + Const.SAVEFILE_EXT + ".bak" ) ) File.delete( saveDirectory + fileName + Const.SAVEFILE_EXT + ".bak" );

		var executor = Executor.create( 1 );
		var i = 0;
		var task = () -> {
			i++;
			if ( i > 10 ) return;

			if ( File.exists( saveDirectory + fileName + Const.SAVEFILE_EXT ) ) {
				sys.io.File.copy( saveDirectory + fileName + Const.SAVEFILE_EXT, saveDirectory + fileName + Const.SAVEFILE_EXT + '.bak' );
				executor.stop();
			}
		};
		executor.submit( task, FIXED_RATE( 100 ) );
	}

	function reattachMainFrom( file : String ) {
		rollbackChanges();

		try {
			sqlite.request( "detach maindb" );
		} catch( e : Dynamic ) {
			#if debug
			trace( "error on detach: " + e );
			#end
		}

		sqlite.request( 'attach database ${sqlite.quote( saveDirectory + file + Const.SAVEFILE_EXT )} as maindb' );
	}

	public function saveGame( fileName : String ) {
		var targetFilePath = saveDirectory + fileName + Const.SAVEFILE_EXT;

		if ( isDbLocatedInMemory( "maindb" ) ) {
			// debug scenario when entry point was not in main menu(i.e. scripted to load level)
			if ( File.exists( targetFilePath ) ) {
				bakSave( fileName );
				File.delete( targetFilePath );
			}
			saveAllLevels();
			commitChanges();
			sqlite.request( 'vacuum maindb into ${sqlite.quote( targetFilePath )}' );
			startTransaction();
		} else if ( currentFile != null && currentFile != fileName ) {
			// saving into other file
			// целевой файл бекапится, а потом удаляется
			if ( File.exists( targetFilePath ) ) {
				bakSave( fileName );
				File.delete( targetFilePath );
			}
			// нам нужно, чтобы в текущем файле не сохранились изменения, поэтому мы сохраняем его копию (.swap),
			// чтобы сохранить изменения и поменять сохранённый файл на тот, в который мы хотим сохраниться, затем первый файл вернуть в прежнее состояние
			sys.io.File.copy( currentFilePath, currentFilePath + ".swap" );

			saveAllLevels();
			commitChanges();

			sys.io.File.copy( currentFilePath, targetFilePath );
			File.delete( currentFilePath );
			FileSystem.rename( currentFilePath + ".swap", currentFilePath );

			reattachMainFrom( fileName );
			startTransaction();
		}

		saveAllLevels();

		// saving general game data, such as celestial map
		var s = new hxbit.Serializer();
		var bytes = s.serialize( GameServer.inst );

		sqlite.request( 'insert into maindb.game (blob) values(
            ${sqlite.quote( haxe.crypto.Base64.encode( bytes ) )}
        )' );

		commitChanges();

		sqlite.request( "PRAGMA foreign_keys=on" );
		currentFile = fileName;
		startTransaction();
	}

	public function saveAllLevels() {
		for ( i in GameServer.inst.levels )
			saveLevel( i );
	}

	public function saveLevel( level : ServerLevel ) : SavedLevel {
		// checking if maindb attached
		if ( isMainDbAttached() ) {
			// dropping "entities" tmx layer in favor of previously saved layer
			var tmxMap : format.tmx.Data.TmxMap = Unserializer.run( haxe.Serializer.run( level.tmxMap ) );
			var entitiesTmxLayer = tmxMap.getLayersByName( 'entities' );

			if ( entitiesTmxLayer != null )
				for ( i in entitiesTmxLayer )
					switch i {
						case LObjectGroup( group ):
							for ( obj in group.objects.copy() ) if ( obj.name != "player" ) group.objects.remove( obj );
						default:
					}

			var cachedLevel = upsertLevelMap( level.lvlName, tmxMap );

			// requesting our newly updated/inserted room to assign sql id to it's instance
			// if ( cachedLevel != null )
			level.sqlId = cachedLevel.id;

			for ( i in Entity.ServerALL ) {
				if ( i.level.sqlId == level.sqlId ) {
					saveEntity( i );
				}
			}
			return cachedLevel;
		}
		return null;
	}

	public function upsertLevelMap( name : String, tmxMap : format.tmx.Data.TmxMap ) : SavedLevel {
		var s = new Serializer();
		var levelBlob = sqlite.quote( Base64.encode( s.serialize( tmxMap ) ) );

		var query = sqlite.request( '
			insert into maindb.rooms (name, tmx) values(
				${sqlite.quote( name )},
				${levelBlob}
			) 
			on conflict(name) do update set 
				name = ${sqlite.quote( name )}, 
				tmx = ${levelBlob} 
				where 
					name = ${sqlite.quote( name )}
			returning *
		' ).next();

		return query;
	}

	function upsertPlayerFeet( player : Player ) {}

	public function saveEntity( entity : Entity ) {
		var s = new hxbit.Serializer();
		var bytes = s.serialize( entity );

		// we remain a shallow copy of the player saying only their feet if we want to know them when we will be bringing this player back again on this level
		if ( Std.isOfType( entity, Player ) ) {
			if ( sqlite.request( '
					select * from maindb.entities 
						where name = "player_shallow_feet" 
							and level_id = ${entity.level.sqlId}' ).hasNext() )

				sqlite.request( '
					update maindb.entities set 
						blob = "${entity.footX}_${entity.footY}"
					where 
						name = "player_shallow_feet"
						and level_id = ${entity.level.sqlId}
				' )
			else

				sqlite.request( '
					insert into maindb.entities (name, blob, level_id) values(
						"player_shallow_feet",
						"${entity.footX}_${entity.footY}",
						${entity.level.sqlId}
					)
				' );
		}

		if ( entity.sqlId != null ) {
			// this entity has been previously saved and is bling updated to db
			sqlite.request( '
				update maindb.entities set
					name = ${sqlite.quote( Std.string( entity ) )},
					blob = ${sqlite.quote( Base64.encode( bytes ) )},
					level_id = ${entity.level.sqlId}
					where id = ${entity.sqlId}
				' );
		} else {
			// this entity is freshly created, or a player if it is also fresh
			sqlite.request( 'insert into maindb.entities (name, blob, level_id) values(
					${sqlite.quote( Std.string( entity ) )},
					${sqlite.quote( Base64.encode( bytes ) )},
					${entity.level.sqlId}
				)' );

			entity.sqlId = sqlite.request( 'select max(id) id from maindb.entities' ).next().id;
		}
	}

	public function getPlayerByNickname( nickname : String ) : SavedPlayer {
		return
			sqlite.request( '
				select * from maindb.players as players 
					inner join maindb.entities as entities 
						on players.entity_id == entities.id
			' ).next();
	}

	// TODO only singleplayer or server-side
	public function loadGame( fileName : String ) {
		rollbackChanges();

		if ( fileName != currentFile ) reattachMainFrom( fileName );
		startTransaction();

		var savedGame = sqlite.request( 'select * from maindb.game' );

		if ( savedGame.hasNext() ) {
			// we do have some saved game
			if ( GameServer.inst != null ) {
				GameServer.inst.destroy();
				@:privateAccess Process._garbageCollector( Process.ROOTS );
			}

			var u = new Serializer();
			u.unserialize( Base64.decode( savedGame.next().blob ), GameServer );
		} else
			Main.inst.startGame();

		// singleplayer player level load
		rollbackChanges();
		startTransaction();

		GameServer.inst.getLevel( loadLevelWithPlayerSingle().name, {} );

		currentFile = fileName;
	}

	// Search for a room where player is saved in and loads it
	public function loadLevelWithPlayerSingle() : SavedLevel {
		var playerEntry = sqlite.request( 'select * from maindb.entities where name = "en.player.Player"' );
		if ( playerEntry.length > 1 ) trace( "loading singleplayer but more than 1 player found..." );

		var cachedLevel = sqlite.request( 'select * from maindb.rooms where id = ${playerEntry.next().level_id}' ).next();
		return cachedLevel;
	}

	public function loadSavedEntities( level : SavedLevel ) {
		var entities = sqlite.request( '
			select * from maindb.entities 
				where level_id = ${level.id} 
					and not name = ${sqlite.quote( "en.player.Player" )}
					and not name like "player_shallow%"
		' );

		if ( entities.hasNext() ) for ( i in entities ) loadEntity( i );
	}

	public function getSavedLevel( level : SavedLevel ) : format.tmx.Data.TmxMap {
		var s = new Serializer();
		var loadedLevel = s.unserialize( Base64.decode( level.tmx ), TmxMap );
		// loadedLevel.sqlId = Std.int(level.id);

		loadSavedEntities( level );

		return loadedLevel;
	}

	public function getLevelByName( name : String ) : SavedLevel {
		var query = sqlite.request( 'select * from maindb.rooms where name = "${name}"' );
		return query.hasNext() ? query.next() : null;
	}

	public function getSavedLevelByName( name : String ) : format.tmx.Data.TmxMap {
		try {
			var levelToBeLoaded = getLevelByName( name );
			if ( levelToBeLoaded != null ) {
				var loadedLevel = getSavedLevel( levelToBeLoaded );
				return loadedLevel;
			} else {
				return null;
			}
		} catch( e : Dynamic ) {
			trace( e );
			return null;
		}
	}

	// checks if any player has been previously saved in db, singleplayer - only
	public function isPlayerSaved() : Bool {
		return sqlite.request( 'select * from maindb.entities where name = "en.player.Player"' ).hasNext();
	}

	// used to load saved player to new-loaded .tmx locations
	public function bringPlayerToLevel( level : SavedLevel ) {
		return sqlite.request( 'update maindb.entities set level_id = ${level.id} where name = "en.player.Player" returning *' );
	}

	public function playerSavedOn( level : ServerLevel ) : SavedEntity {
		return sqlite.request( 'select * from maindb.entities where name = "en.player.Player" and level_id = ${level.sqlId}' ).next();
	}

	public function getPlayerShallowFeet( player : Player ) {
		return sqlite.request( 'select * from maindb.entities where name = "player_shallow_feet" and level_id = ${player.level.sqlId}' ).next();
	}

	/**basically a fix for entity duplicates when disposing**/
	public function removeEntityById( id : Int ) {
		sqlite.request( 'delete from maindb.entities where id=$id' );
	}

	public function loadEntity( entity : SavedEntity ) : Entity {
		try {
			var u = new Serializer();
			var ent = cast( u.unserialize( Base64.decode( entity.blob ), Type.resolveClass( entity.name ) ), Entity );
			ent.sqlId = entity.id;
			return ent;
		} catch( e : Dynamic ) {
			trace( "error while unserializing entity: " + e, haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
		}
		return null;
	}
}
