package game.server;

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
import utils.MapCache;
import utils.tools.Save;
import utils.Util;

using en.util.EntityUtil;

/**
	Логика игры на сервере
**/
class GameServer extends Process implements Serializable {

    public static var inst : GameServer;

    public var execAfterLvlLoad : EventSignal0;

    public var levels : Map<String, ServerLevel>;

    @:s public var _fields : NavigationFields;
    @:s public var seed : String;

    static var entClasses : List<Class<Entity>>;

    public function new( ?seed : String ) {
        super( );
        inst = this;

        this.seed = seed;

        CompileTime.importPackage( "en" );
        entClasses = CompileTime.getAllClasses( Entity );

        levels = [];

        Data.load( hxd.Res.data.entry.getText( ) );

        // new Navigation();

        // generating initial asteroids to have where to put player on
        // we do not yet have need to save stuff about asteroids, temporal clause
        // Navigation.serverInst.fields.push(
        // 	new NavigationField(
        // 		seed,
        // 		0,
        // 		0
        // 	));
    }

    /**
		added in favor of unserializing

		@param mockConstructor if true, then we will execute dn.Process constructor clause
	**/
    public function initLoad( ?mockConstructor = true ) {
        if ( mockConstructor ) {
            init( );

            if ( parent == null ) Process.ROOTS.push( this ); else
                parent.addChild( this );
        }

        inst = this;
    }

    // var testSLevel : ServerLevel = null;

    /**
		starts entrypoint level and slaps player onto it
	**/
    public function newPlayer( nickname : String, uid : Int, clientController : ClientController ) : Player {
        // our temporary entrypoint
        var entryPointLevel = "ship_pascal.tmx";

        var sLevel = getLevel( entryPointLevel, {} );
        // раз игрок новый, то спавним его из tmxObject
        var player = spawnByName( "en.player.$Player", entClasses, sLevel, [nickname, uid, clientController] ).as( Player );

        return player;
    }

    public function getLevel( name : String, playerLoadConf : LevelLoadPlayerConfig ) : ServerLevel {
        name = Util.unifyLevelName( name );

        if ( levels[name] != null ) return levels[name];

        var savedLevel = Save.inst.getLevelByName( name );

        if ( savedLevel != null ) {
            var s = new Serializer();
            var sLevel = startLevelFromParsedTmx(
                s.unserialize( haxe.crypto.Base64.decode( savedLevel.tmx ), TmxMap ),
                savedLevel.name,
                playerLoadConf
            );
            levels[name].sqlId = Std.int( savedLevel.id );
            Save.inst.loadSavedEntities( savedLevel );
            return sLevel;
        } else {
            return startLevelFromParsedTmx( MapCache.inst.get( name ), name, playerLoadConf );
        }
    }

    public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String, playerLoadConf : LevelLoadPlayerConfig ) : ServerLevel {
        execAfterLvlLoad = new EventSignal0();

        var sLevel : ServerLevel = levels[name];

        if ( sLevel == null ) {
            sLevel = new ServerLevel( tmxMap );
            levels[name] = sLevel;
            sLevel.lvlName = name;
        }

        // получаем sql id для уровня
        var loadedLevel = Save.inst.saveLevel( sLevel );

        // Загрузка игрока при переходе в другую локацию
        // Save.inst.bringPlayerToLevel( loadedLevel );
        var cachedPlayer = Save.inst.playerSavedOn( sLevel );

        if ( cachedPlayer != null ) {
            // это значит, что инстанс игрока был ранее создан и делать нового не надо
            // for ( e in level.entitiesTmxObj )
            // 	if ( playerLoadConf.manual
            // 		|| (
            // 			!e.properties.existsType("className", PTString)
            // 			|| e.properties.getString("className") != "en.player.$Player"
            // 		) ) {
            // 			var ent = searchAndSpawnEnt(e, entClasses);
            // 			ent.level = level;
            // 	}
            Save.inst.loadEntity( cachedPlayer );
        } else {
            for ( e in sLevel.entitiesTmxObj ) {
                var ent = searchAndSpawnEnt( e, entClasses, sLevel, [], [Player] );

                // if ( ent != null )

                // 	ent.level = sLevel;
            }
        }

        // if ( playerLoadConf.acceptTmxPlayerCoord ) {
        // 	delayer.addF(() -> {
        // 		var playerEnt : TmxObject = null;
        // 		for ( e in level.entitiesTmxObj )
        // 			if (
        // 				!e.properties.existsType("className", PTString)
        // 				|| e.properties.getString("className") == "en.player.$Player"
        // 			)
        // 				playerEnt = e;
        // 		if ( playerEnt != null )
        // 			player.setFeetPos(
        // 				level.cartToIsoLocal(playerEnt.x, playerEnt.y).x,
        // 				level.cartToIsoLocal(playerEnt.x, playerEnt.y).y
        // 			);
        // 	}, 1);
        // }

        // if ( playerLoadConf.acceptSqlPlayerCoord ) {
        // 	delayer.addF(() -> {
        // 		var playerEnt = Save.inst.getPlayerShallowFeet(player);
        // 		if ( playerEnt != null ) {
        // 			var blob = '${playerEnt.blob}'.split("_");
        // 			player.setFeetPos(Std.parseInt(blob[0]), Std.parseInt(blob[1]));
        // 		}
        // 	}, 1);
        // }

        // в коллбек надо обернуть
        // delayer.addF(() -> {
        // applyTmxObjOnEnt();
        // }, 10);
        return sLevel;
    }

    @:keep
    public function customSerialize( ctx : hxbit.Serializer ) {
        // navigation
        var s = new hxbit.Serializer();
        ctx.addBytes( s.serialize( Navigation.serverInst ) );
    }

    /** при десеаризации создается пустой инстанс Game, отсюда в Game.inst будет выгружены все параметры **/
    @:keep
    public function customUnserialize( ctx : hxbit.Serializer ) {
        initLoad( );

        // navigation
        var s = new Serializer();
        s.unserialize( ctx.getBytes( ), Navigation );
    }

    /**
		search and spawn entity	
		in fact only needed for player searching  
	**/
    function spawnByName( name : String, entClasses : List<Class<Entity>>, sLevel : ServerLevel, ?args : Array<Dynamic> ) : Entity {
        for ( obj in sLevel.entitiesTmxObj ) {
            if ( obj.name == name
            || ( obj.properties.existsType( "className", PTString )
            && obj.properties.getString( "className" ) == name ) ) {
                return searchAndSpawnEnt( obj, entClasses, sLevel, args );
            }
        }

        return null;
    }

    // Search for name from parsed entNames Entity classes and spawn it, creates static SpriteEntity and puts name into spr group if not found
    function searchAndSpawnEnt(
        e : TmxObject,
        entClasses : List<Class<Entity>>,
        sLevel : ServerLevel,
        ?args : Array<Dynamic>,
        ?exclude : Array<Class<Entity>>
    ) : Entity {

        if ( args == null ) args = [];
        exclude = exclude == null ? [] : exclude;

        var resultEntity : Entity = null;
        var footZ : Float =
        {
            ( sLevel.tmxMap.properties.exists( "defaultEntitySpawnLevel" ) ?
            sLevel.tmxMap.properties.getInt( "defaultEntitySpawnLevel" ) :
            e.properties.exists( "z" ) ?
            e.properties.getInt( "z" ) :
            0 ) * sLevel.tmxMap.tileHeight + 1;
        }

        var x = e.x + footZ;
        var y = e.y + footZ;
        var tsTile : TmxTilesetTile = null;

        switch e.objectType {
            case OTTile( gid ):
                tsTile = Tools.getTileByGid( sLevel.tmxMap, gid );
            default:
                "";
        }
        // Парсим все классы - наследники en.Entity и спавним их
        for ( eClass in entClasses ) {
            if ( exclude.contains( eClass ) ) continue;

            // смотрим во всех наследников Entity и спавним, если совпадает. Если не совпадает, то
            // значит что потом мы смотрим настройку className тайла из тайлсета, который мы пытаемся заспавнить
            if ( (
                Util.eregCompTimeClass.match( '$eClass'.toLowerCase( ) )
                && Util.eregCompTimeClass.matched( 1 ) == e.name
            ) || (
                tsTile.properties.existsType( "className", PTString )
                && tsTile.properties.getString( "className" ) == '$eClass'
            )
            ) {
                var totalArgs : Array<Dynamic> = [x, y, footZ, e];
                totalArgs = totalArgs.concat( args );
                resultEntity = Type.createInstance( eClass, totalArgs );
            }
        }

        // если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
        if ( resultEntity == null
        && Util.eregFileName.match( tsTile.image.source )
        && !tsTile.properties.existsType( "className", PTString ) ) {
            resultEntity = new SpriteEntity( x, y, Util.eregFileName.matched( 1 ), e );
        }

        if ( resultEntity != null ) @:privateAccess {
            resultEntity.level = sLevel;
            sLevel.addEntity( resultEntity );
            resultEntity.serverApplyTmx( );
        }

        return resultEntity;
    }

    function gc( ) {
        if ( Entity.GC == null || Entity.GC.length == 0 ) return;

        for ( e in Entity.GC ) e.dispose( );
        for ( level in levels )
            Entity.GC = [];
    }

    override function onDispose( ) {
        super.onDispose( );

        for ( e in Entity.ServerALL ) e.destroy( );
        gc( );
    }

    override function update( ) {
        super.update( );

        for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessPreUpdate( );
        for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessUpdate( );
        for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessPostUpdate( );
        for ( e in Entity.ServerALL ) if ( !e.destroyed ) e.headlessFrameEnd( );
        gc( );
    }
}
