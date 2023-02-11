package game.server;

import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import en.Entity;
import format.tmx.*;
import game.client.GameClient.LevelLoadPlayerConfig;
import game.server.factory.EntityFactory;
import hxbit.Serializer;
import util.MapCache;
import util.Util;
import util.tools.Save;

using en.util.EntityUtil;
using util.Extensions.TmxPropertiesExtension;

/**
	Логика игры на сервере
**/
class GameServer extends Process {

	public static var inst : GameServer;

	public static var entClasses : List<Class<Entity>> = CompileTime.getAllClasses( Entity );

	public final entityFactory : EntityFactory;

	public var execAfterLvlLoad : EventSignal0;
	public var levels : Map<String, ServerLevel> = [];

	@:s public var seed : String;

	public function new( ?seed : String ) {
		super();
		inst = this;
		this.seed = seed;

		entityFactory = new EntityFactory();
		entityFactory.game = this;

		CompileTime.importPackage( "en" );

		Data.load( hxd.Res.data.entry.getText() );
	}

	// TODO
	public function getLevel( name : String ) : ServerLevel {
		name = Util.unifyLevelName( name );

		if ( levels[name] != null ) return levels[name];

		var level = createLevel( Data.world.get( Data.WorldKind.overworld ) );
		levels[name] = level;

		return level;
	}

	function createLevel( conf : Data.World ) : ServerLevel {
		var level = new ServerLevel();
		level.cdb = conf;

		level.generator = Type.createInstance(
			game.server.generation.ClassResolver.resolve( level.cdb.generator ), []
		);

		level.generator.level = level;
		level.generator.placeSnippet( 0, 0, "ship_pascal" );

		return level;
	}

	function gc() {
		if ( Entity.GC == null || Entity.GC.length == 0 ) return;

		for ( e in Entity.GC ) e.dispose();
		for ( level in levels )
			Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		for ( e in Entity.ServerALL ) e.destroy();
		gc();
	}

	override function update() {
		super.update();

		for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessPreUpdate();
		for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessUpdate();
		for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessPostUpdate();
		for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessFrameEnd();
		gc();
	}
}
