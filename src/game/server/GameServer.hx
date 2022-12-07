package game.server;

import game.server.factory.EntityFactory;
import net.Server;
import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import en.Entity;
import en.player.Player;
import en.SpriteEntity;
import format.tmx.*;
import format.tmx.Data;
import game.client.GameClient.LevelLoadPlayerConfig;
import hxbit.Serializable;
import hxbit.Serializer;
import net.ClientController;
import ui.Navigation;
import util.MapCache;
import util.tools.Save;
import util.Util;
import util.EregUtil;

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

	@:s public var _fields : NavigationFields;
	@:s public var seed : String;

	public function new( ?seed : String ) {
		super();
		inst = this;
		this.seed = seed;

		entityFactory = new EntityFactory();
		entityFactory.game = this;

		CompileTime.importPackage( "en" );
		// entClasses = CompileTime.getAllClasses( Entity );

		Data.load( hxd.Res.data.entry.getText() );
	}

	public function getLevel( name : String, playerLoadConf : LevelLoadPlayerConfig ) : ServerLevel {
		name = Util.unifyLevelName( name );

		if ( levels[name] != null ) return levels[name];

		var savedLevel = Save.inst.getLevelByName( name );

		if ( savedLevel != null ) {
			var s = new Serializer();
			var sLevel = startLevelFromTmx(
				s.unserialize( haxe.crypto.Base64.decode( savedLevel.tmx ), TmxMap ),
				savedLevel.name,
				playerLoadConf
			);
			levels[name].sqlId = Std.int( savedLevel.id );
			Save.inst.loadSavedEntities( savedLevel );
			return sLevel;
		} else {
			return startLevelFromTmx( MapCache.inst.get( name ), name, playerLoadConf );
		}
	}

	public function startLevelFromTmx(
		tmxMap : TmxMap,
		name : String,
		playerLoadConf : LevelLoadPlayerConfig
	) : ServerLevel {
		execAfterLvlLoad = new EventSignal0();

		var sLevel : ServerLevel = levels[name];

		if ( sLevel == null ) {
			sLevel = new ServerLevel( tmxMap );
			levels[name] = sLevel;
			sLevel.lvlName = name;
		}

		// получаем sql id для уровня
		var loadedLevel = Save.inst.saveLevel( sLevel );

		for ( e in sLevel.entitiesTmxObj ) {
			entityFactory.spawnEntity( e, sLevel );
		}

		return sLevel;
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
