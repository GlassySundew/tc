import differ.shapes.Polygon;
import differ.math.Vector;
import en.player.Player;
import hxbit.Serializable;
import ui.Navigation;
import GameClient.LevelLoadPlayerConfig;
import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import format.tmx.*;
import format.tmx.Data;
import hxbit.Serializer;
import tools.Save;
import ui.Navigation.NavigationFields;

/**
	Логика игры на сервере
**/
class GameServer extends Process implements Serializable {

	public static var inst : GameServer;

	public var network( get, never ) : Bool;

	inline function get_network() return false;

	public var lvlName : String;

	public var tmxMap : TmxMap;

	public var tmxMapOg : TmxMap;

	public var execAfterLvlLoad : EventSignal0;

	public var levels : Map<String, ServerLevel>;

	@:s public var _fields : NavigationFields;
	@:s public var seed : String;

	static var entClasses : List<Class<Entity>>;

	public function new( ?seed : String ) {
		super();
		inst = this;

		this.seed = seed;

		CompileTime.importPackage( "en" );
		entClasses = CompileTime.getAllClasses( Entity );

		levels = [];

		Data.load( hxd.Res.data.entry.getText() );

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
			init();

			if ( parent == null ) Process.ROOTS.push( this ); else
				parent.addChild( this );
		}

		inst = this;
	}

	/** 
		starts entrypoint level and slaps player onto it
	**/
	public function initializePlayer( nickname : String, uid : Int ) : Player {
		// our temporary entrypoint
		var entryPointLevel = "ship_pascal.tmx";
		var sLevel = startLevel( entryPointLevel, {} );
		// раз игрок новый, то спавним его из tmxObject
		var player = sasByName( "en.player.$Player", entClasses, sLevel, [nickname, uid] ).as( Player );

		return player;
	}

	public function startLevel( name : String, playerLoadConf : LevelLoadPlayerConfig ) : ServerLevel {
		if ( levels[name] != null )
			return levels[name];
		// Save.inst.saveLevel(levels[name]);

		var savedLevel = Save.inst.getLevelByName( name.split( "." )[0] );

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
			tmxMap = MapCache.inst.get( name );
			return startLevelFromParsedTmx( tmxMap, name, playerLoadConf );
		}
	}

	public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String, playerLoadConf : LevelLoadPlayerConfig ) : ServerLevel {
		execAfterLvlLoad = new EventSignal0();

		var sLevel : ServerLevel = levels[name];

		if ( sLevel == null ) {
			sLevel = new ServerLevel( tmxMap );
			levels[name] = sLevel;
			sLevel.lvlName = lvlName = name.split( '.' )[0];
		}

		// получаем sql id для уровня
		var loadedLevel = Save.inst.saveLevel( sLevel );

		// Загрузка игрока при переходе в другую локацию
		Save.inst.bringPlayerToLevel( loadedLevel );
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
		initLoad();

		// navigation
		var s = new Serializer();
		s.unserialize( ctx.getBytes(), Navigation );
	}

	/** 
		search and spawn entity	
		in fact only needed for player searching  
	**/
	function sasByName( name : String, entClasses : List<Class<Entity>>, sLevel : ServerLevel, ?args : Array<Dynamic> ) : Entity {
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

		var resultEntity = null;

		var isoX = 0., isoY = 0.;
		if ( tmxMap.orientation == Isometric ) {
			// все объекты в распаршенных слоях уже с конвертированными координатами
			// entities export lies ahead
			isoX = sLevel.cartToIsoLocal( e.x, e.y ).x;
			isoY = sLevel.cartToIsoLocal( e.x, e.y ).y;
		}

		var tsTile : TmxTilesetTile = null;

		switch e.objectType {
			case OTTile( gid ):
				tsTile = Tools.getTileByGid( tmxMap, gid );
			default:
				"";
		}

		// Парсим все классы - наследники en.Entity и спавним их
		for ( eClass in entClasses ) {
			if ( exclude.contains( eClass ) ) continue;

			// смотрим во всех наследников Entity и спавним, если совпадает. Если не совпадает, то
			// значит что потом мы смотрим настройку className тайла из тайлсета, который мы пытаемся заспавнить
			if ( (
				eregCompTimeClass.match( '$eClass'.toLowerCase() )
				&& eregCompTimeClass.matched( 1 ) == e.name
			)
				|| (
					tsTile.properties.existsType( "className", PTString )
					&& tsTile.properties.getString( "className" ) == '$eClass'
				)
			) {
				var totalArgs : Array<Dynamic> = [isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, e];
				totalArgs = totalArgs.concat( args );
				resultEntity = Type.createInstance( eClass, totalArgs );
			}
		}

		// если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
		if ( resultEntity == null
			&& eregFileName.match( tsTile.image.source )
			&& !tsTile.properties.existsType( "className", PTString ) ) {
			return {
				resultEntity = new SpriteEntity( isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, eregFileName.matched( 1 ), e );
			}
		}

		if ( resultEntity != null ) {
			resultEntity.level = sLevel;
			sLevel.entities.push( resultEntity );
		}

		return resultEntity;
	}

	public function applyTmxObjOnEnt( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls

		// parsing collision objects from 'colls' tileset
		var entitiesTs : TmxTileset = null;

		for ( tileset in tmxMap.tilesets ) {
			if ( StringTools.contains( tileset.source, "entities" ) ) {
				entitiesTs = tileset;
			}
		}

		var ents = ent != null ? [ent] : Entity.ServerALL;

		for ( tile in entitiesTs.tiles ) {
			if ( eregFileName.match( tile.image.source ) ) {
				var picName = {
					if ( tile.properties.existsType( "className", PTString ) ) {
						var className = tile.properties.getString( "className" );
						eregCompTimeClass.match( className );
						eregCompTimeClass.matched( 1 ).toLowerCase();
					} else
						eregFileName.matched( 1 );
				}

				for ( ent in ents ) {
					eregClass.match( '$ent'.toLowerCase() );
					var entityName = eregClass.matched( 1 );

					var objx = 0.;

					if ( entityName == picName
						|| ( ent.sprFrame != null && ent.sprFrame.group == picName ) ) {

						// соотношение, которое в конце будет применено к entity
						var center = new Vector();

						for ( obj in tile.objectGroup.objects ) {
							switch obj.objectType {
								case OTRectangle:
								case OTEllipse:
									var shape = new differ.shapes.Circle( 0, 0, obj.width / 2 );
									var cent = new Vector(
										obj.width / 2,
										obj.height / 2
									);

									ent.collisions.set( shape, new differ.math.Vector( obj.x + cent.x, obj.y + cent.y ));

										if ( center.x == 0 && center.y == 0 ) {
											center.x = cent.x + obj.x;
											center.y = cent.y + obj.y;
										}
								case OTPoint:
									switch obj.name {
										case "center":
											center.x = obj.x;
											center.y = obj.y;
									}
								case OTPolygon( points ):
									var pts = makePolyClockwise( points );
									rotatePoly( obj, pts );

									var cent = getProjectedDifferPolygonRect( obj, points );

									var verts : Array<Vector> = [];
									for ( i in pts ) verts.push( new Vector( i.x, i.y ) );

									var poly = new Polygon( 0, 0, verts );

									poly.scaleY = -1;
									ent.collisions.set(
										poly,
										new differ.math.Vector( obj.x, obj.y )
									);
									objx = obj.x;

									if ( center.x == 0 && center.y == 0 ) {
										center.x = cent.x + obj.x;
										center.y = cent.y + obj.y;
									}
								default:
							}
						}

						// ending serving this particular entity 'ent' here
						var pivotX = center.x;
						var pivotY = center.y;

						ent.pivot = { x : pivotX, y : pivotY };

						var actualX = Std.int( ent.tmxObj.width ) >> 1;
						var actualY = Std.int( ent.tmxObj.height );

						ent.footX -= actualX - pivotX;
						ent.footY += actualY - pivotY;

						#if depth_debug
						if ( ent.mesh != null )
							ent.mesh.renewDebugPts();
						#end

						try {
							cast( ent, en.InteractableEntity ).rebuildInteract();
						}
						catch( e : Dynamic ) {}

						if ( Std.isOfType( ent, SpriteEntity ) && tile.properties.exists( "interactable" ) ) {
							cast( ent, SpriteEntity ).interactable = tile.properties.getBool( "interactable" );
						}
					}
				}
			}
		}
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
