import h2d.Text;
import haxe.Unserializer;
import hx.concurrent.Future.FutureResult;
import mapgen.MapGen;
import hx.concurrent.executor.Executor;
import Level.StructTile;
import cherry.soup.EventSignal.EventSignal0;
import differ.math.Vector;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import dn.Process;
import en.player.Player;
import format.tmx.*;
import format.tmx.Data;
import h3d.scene.CameraController;
import h3d.scene.Object;
import hxbit.Serializer;
import tools.Save;
import tools.Settings;
import ui.Hud;
import ui.Navigation;
import ui.PauseMenu;
/** 
	@param manual debug parameter, if true, player will not be kept and will be load clear from tmx entity named 'player'
	@param acceptTmxPlayerCoord same as manual, but the existing player instance wont be thrown off and only coords from tmx object 'player' will be applied to loaded player instance
	@param acceptSqlPlayerCoord we are keeping player sql entry on previously visited locations to only apply their coords to our existing Player instance if visiting them once again
**/
@:structInit
class LevelLoadPlayerConfig {
	public var manual : Bool;
	public var acceptTmxPlayerCoord : Bool;
	public var acceptSqlPlayerCoord : Bool;

	public function new( ?manual = false, ?acceptTmxPlayerCoord = false, ?acceptSqlPlayerCoord = false ) {
		this.manual = manual;
		this.acceptTmxPlayerCoord = acceptTmxPlayerCoord;
		this.acceptSqlPlayerCoord = acceptSqlPlayerCoord;
	}
}

class Game extends Process implements IGame implements hxbit.Serializable {
	public static var inst : Game;

	public var network(get, never) : Bool;

	inline function get_network() return false;

	public var lvlName : String;
	public var ca : dn.heaps.Controller.ControllerAccess;
	public var camera : Camera;

	private var cam : CameraController;

	public var level : Level;

	public var tmxMap : TmxMap;

	public var player : en.player.Player;
	public var hud : Hud;
	public var fx : Fx;

	public var structTiles : Array<StructTile> = [];

	public var execAfterLvlLoad : EventSignal0;

	public var suspended : Bool = false;
	public var pauseCycle : Bool = false;

	@:s public var seed : Null<String>;
	public var navFieldsGenerated : Null<Int>;

	#if game_tmod
	var stats : h2d.Text;
	#end

	public function new( ?seed : String ) {
		super(Main.inst);

		if ( seed == null ) seed = Random.string(10);
		this.seed = seed;

		initLoad(false);

		new Navigation(
			Const.jumpReach,
			'${Game.inst.seed}'
		);

		// generating initial asteroids to have where to put player on
		// we do not yet have need to save stuff about asteroids, temporal clause
		@:privateAccess
		Navigation.inst.fields.push(new NavigationField(
			seed,
			0,
			0 // ,
			// Navigation.inst.bodiesContainer
		));

		// for( i in Navigation.inst.fields) {
		// 	for( target in i.targets) {
		// 		target.createGenerator();

		// 	}
		// }

		new AxesHelper(Boot.inst.s3d);
		new GridHelper(Boot.inst.s3d);
	}
	/**
		added in favor of unserializing

		@param mockConstructor if true, then we will execute dn.Process constructor clause
	**/
	public function initLoad( ?mockConstructor = true ) {
		#if game_tmod
		stats = new Text(Assets.fontPixel, Boot.inst.s2d);
		#end

		if ( mockConstructor ) {
			init();

			if ( parent == null ) Process.ROOTS.push(this); else
				parent.addChild(this);
		}

		inst = this;

		ca = Main.inst.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.inst.root, Const.DP_BG);

		camera = new Camera();
	}

	public function onCdbReload() {}

	@:keep
	public function customSerialize( ctx : hxbit.Serializer ) {
		// navigation
		var s = new hxbit.Serializer();
		ctx.addBytes(s.serialize(Navigation.inst));
	}
	/** при десеаризации создается пустой инстанс Game, отсюда в Game.inst будет выгружены все параметры **/
	@:keep
	public function customUnserialize( ctx : hxbit.Serializer ) {
		initLoad();

		// navigation
		var s = new Serializer();
		s.unserialize(ctx.getBytes(), Navigation);

		Game.inst.delayer.addF(() -> {
			for ( field in Navigation.inst.fields ) {
				@:privateAccess Navigation.inst.bodiesContainer.addChild(field.object);
				// for ( target in field.targets ) {
				// 	field.addChild(target);
				// }
			}
		}, 1);
	}

	public function restartLevel() {
		// startLevel(lvlName);
	}
	/**
		@param manual debug parameter, if true, player won't be moved on level change
	**/
	public function startLevel( name : String, playerLoadConf : LevelLoadPlayerConfig ) {
		if ( level != null )
			Save.inst.saveLevel(level);

		// in fact its not only from cache, it will pull level that was already pushed to db
		var levelFromCache = Save.inst.getLevelByName(name.split(".")[0]);

		if ( levelFromCache != null ) {
			startLevelFromParsedTmx(
				Unserializer.run(haxe.crypto.Base64.decode(levelFromCache.tmx).toString()),
				levelFromCache.name,
				playerLoadConf
			);
			level.sqlId = Std.int(levelFromCache.id);
			Save.inst.loadSavedEntities(levelFromCache);
		} else {
			tmxMap = MapCache.inst.get(name);
			startLevelFromParsedTmx(tmxMap, name, playerLoadConf);
		}
	}

	// Search for name from parsed entNames Entity classes and spawns it, creates static SpriteEntity and puts name into spr group if not found
	function searchAndSpawnEnt( e : TmxObject, entClasses : List<Class<Entity>> ) {
		var isoX = 0., isoY = 0.;
		if ( tmxMap.orientation == Isometric ) {
			// все объекты в распаршенных слоях уже с конвертированными координатами
			// entities export lies ahead
			isoX = Level.inst.cartToIsoLocal(e.x, e.y).x;
			isoY = Level.inst.cartToIsoLocal(e.x, e.y).y;
		}

		var source = "";
		// var tilesetTile : TmxTilesetTile = null;

		switch e.objectType {
			case OTTile(gid):
				source = Tools.getTileByGid(tmxMap, gid).image.source;
			default:
				"";
		}

		// Парсим все классы - наследники en.Entity и спавним их
		for ( eClass in entClasses ) {
			if ( eregCompTimeClass.match('$eClass'.toLowerCase()) ) {

				// смотрим во всех наследников Entity и спавним, если совпадает
				if ( eregCompTimeClass.matched(1) == e.name ) {
					Type.createInstance(eClass, [isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, e]);
					return;
				} else {
					// значит что сейчас мы смотрим настройку className тайла из тайлсета, который мы пытаемся заспавнить
					switch e.objectType {
						case OTTile(gid):
							for ( tile in Tools.getTilesetByGid(tmxMap, gid).tiles ) {
								if (
									tile.image.source == source
									&& tile.properties.existsType("className", PTString)
									&& tile.properties.getString("className") == '$eClass'
								) {
									Type.createInstance(eClass, [isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, e]);
									return;
								}
							}
						default:
					}
				}
			}
		}

		// если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
		if ( eregFileName.match(source) ) {
			new SpriteEntity(isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, eregFileName.matched(1), e);
			return;
		}
	}

	public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String, playerLoadConf : LevelLoadPlayerConfig ) {
		this.tmxMap = tmxMap;
		engine.clear(0, 1);
		execAfterLvlLoad = new EventSignal0();

		if ( level != null ) {
			level.destroy();
			for ( e in Entity.ALL ) {
				e.destroy();
			}
			gc();
		}
		level = new Level(tmxMap);
		level.lvlName = lvlName = name.split('.')[0];

		// получаем sql id для уровня
		var loadedLevel = Save.inst.saveLevel(level);

		// Entity spawning
		CompileTime.importPackage("en");
		var entClasses = CompileTime.getAllClasses(Entity);

		// Загрузка игрока при переходе в другую локацию
		Save.inst.bringPlayerToLevel(loadedLevel);
		var cachedPlayer = Save.inst.playerSavedOn(level);

		if ( cachedPlayer != null ) {
			// это значит, что инстанс игрока был ранее создан и делать нового не надо
			for ( e in level.entities ) if ( playerLoadConf.manual
				|| (
					!e.properties.existsType("className", PTString)
					|| e.properties.getString("className") != "en.player.$Player"
				) ) {
					searchAndSpawnEnt(e, entClasses);
			}
			Save.inst.loadEntity(cachedPlayer);
		} else {
			for ( e in level.entities )
				searchAndSpawnEnt(e, entClasses);
		}

		player = Player.inst;

		if ( playerLoadConf.acceptTmxPlayerCoord ) {
			delayer.addF(() -> {
				var playerEnt : TmxObject = null;
				for ( e in level.entities )
					if (
						!e.properties.existsType("className", PTString)
						|| e.properties.getString("className") == "en.player.$Player"
					)
						playerEnt = e;
				if ( playerEnt != null )
					player.setFeetPos(
						level.cartToIsoLocal(playerEnt.x, playerEnt.y).x,
						level.cartToIsoLocal(playerEnt.x, playerEnt.y).y
					);

				targetCameraOnPlayer();
			}, 1);
		}

		if ( playerLoadConf.acceptSqlPlayerCoord ) {
			delayer.addF(() -> {
				var playerEnt = Save.inst.getPlayerShallowFeet(player);
				if ( playerEnt != null ) {
					var blob = '${playerEnt.blob}'.split("_");
					player.setFeetPos(Std.parseInt(blob[0]), Std.parseInt(blob[1]));
				}
				targetCameraOnPlayer();
			}, 1);
		}

		delayer.addF(() -> {
			hideStrTiles();
			Process.resizeAll();
		}, 3);

		applyTmxObjOnEnt();

		targetCameraOnPlayer();
		return level;
	}

	public function targetCameraOnPlayer() {
		camera.target = player;
		camera.recenter();
	}

	public function applyTmxObjOnEnt( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls

		// parsing collision objects from 'colls' tileset
		var entitiesTs : TmxTileset = null;

		for ( tileset in tmxMap.tilesets ) {
			if ( StringTools.contains(tileset.source, "entities") ) {
				entitiesTs = tileset;
			}
		}

		var ents = ent != null ? [ent] : Entity.ALL;

		for ( tile in entitiesTs.tiles ) {
			if ( eregFileName.match(tile.image.source) ) {
				var picName = {
					if ( tile.properties.existsType("className", PTString) ) {
						var className = tile.properties.getString("className");
						eregCompTimeClass.match(className);
						eregCompTimeClass.matched(1).toLowerCase();
					} else
						eregFileName.matched(1);
				}

				for ( ent in ents ) {
					eregClass.match('$ent'.toLowerCase());
					var entityName = eregClass.matched(1);

					if ( entityName == picName
						|| ent.spr.groupName == picName ) {

						// соотношение, которое в конце будет применено к entity
						var center = new Vector();

						for ( obj in tile.objectGroup.objects ) {
							switch obj.objectType {
								case OTRectangle:
								case OTEllipse:
									var shape = new differ.shapes.Circle(0, 0, obj.width / 2);
									var cent = new Vector(
										obj.width / 2,
										obj.height / 2
									);

									ent.collisions.set(shape,
										{
											cent : new h3d.Vector(cent.x, cent.y),
											offset : new h3d.Vector(obj.x + cent.x, obj.y + cent.y)
										});

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
								case OTPolygon(points):
									var pts = makePolyClockwise(points);
									rotatePoly(obj, pts);

									var cent = getProjectedDifferPolygonRect(obj, points);

									var verts : Array<Vector> = [];
									for ( i in pts ) verts.push(new Vector(i.x, i.y));

									var poly = new Polygon(0, 0, verts);

									poly.scaleY = -1;
									ent.collisions.set(
										poly,
										{
											cent : new h3d.Vector(cent.x, cent.y),
											offset : new h3d.Vector(obj.x, obj.y)
										}
									);

									if ( center.x == 0 && center.y == 0 ) {
										center.x = cent.x + obj.x;
										center.y = cent.y + obj.y;
									}
								default:
							}
						}

						// ending serving this particular entity 'ent' here
						var pivotX = (center.x) / ent.spr.tile.width;
						var pivotY = (center.y) / ent.spr.tile.height;

						ent.setPivot(pivotX, pivotY);

						var actualX = ent.spr.tile.width / 2;
						var actualY = ent.spr.tile.height;

						ent.footX -= actualX - ent.spr.pivot.centerFactorX * ent.spr.tile.width;
						ent.footY += actualY - ent.spr.pivot.centerFactorY * ent.spr.tile.height;

						#if depth_debug
						ent.mesh.renewDebugPts();
						#end

						try {
							cast(ent, Interactive).rebuildInteract();
						}
						catch( e:Dynamic ) {}

						if ( Std.isOfType(ent, SpriteEntity) && tile.properties.exists("interactable") ) {
							cast(ent, SpriteEntity).interactable = tile.properties.getBool("interactable");
						}
					}
				}
			}
		}

		execAfterLvlLoad.dispatch();
		execAfterLvlLoad.removeAll();
	}

	public function gc() {
		if ( Entity.GC == null || Entity.GC.length == 0 ) return;

		for ( e in Entity.GC ) e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();
		if ( Player.inst != null ) {
			Player.inst.saveSettings();
		}
		Settings.saveSettings();

		inst = null;

		#if game_tmod
		if ( stats != null ) stats.remove();
		#end

		if ( camera != null ) camera.destroy();
		for ( e in Entity.ALL ) e.destroy();
		gc();

		if ( PauseMenu.inst != null ) PauseMenu.inst.destroy();
	}

	public override function onResize() {
		super.onResize();
	}

	override function update() {
		super.update();

		#if game_tmod
		stats.text = "tmod: " + tmod;
		#end

		pauseCycle = false;

		// Updates
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.preUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.update();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.postUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.frameEnd();
		gc();
	}

	public function showStrTiles() {
		for ( i in structTiles ) i.visible = true;
	}

	public function hideStrTiles() {
		for ( i in structTiles ) i.visible = false;
	}

	override function pause() {
		super.pause();
		if ( Player.inst != null && Player.inst.holdItem != null ) Player.inst.holdItem.visible = false;
	}

	override function resume() {
		super.resume();
		if ( Player.inst != null && Player.inst.holdItem != null ) Player.inst.holdItem.visible = true;
	}

	public function suspendGame() {
		if ( suspended ) return;

		suspended = true;
		dn.heaps.slib.SpriteLib.DISABLE_ANIM_UPDATES = true;

		// Pause other process
		for ( p in Process.ROOTS ) if ( p != this ) p.pause();

		// Create mask
		root.visible = true;
		root.removeChildren();
	}

	public function resumeGame() {
		if ( !suspended ) return;
		dn.heaps.slib.SpriteLib.DISABLE_ANIM_UPDATES = false;

		delayer.addF(function () {
			root.visible = false;
			root.removeChildren();
		}, 1);
		suspended = false;

		for ( p in Process.ROOTS ) if ( p != this ) p.resume();
	}

	public function toggleGamePause() {
		if ( suspended ) {
			resumeGame();
		} else
			suspendGame();
	}
}

// debug stuff
class AxesHelper extends h3d.scene.Graphics {
	public function new( ?parent : h3d.scene.Object, size = 2.0, colorX = 0xEB304D, colorY = 0x7FC309, colorZ = 0x288DF9, lineWidth = 2.0 ) {
		super(parent);

		material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");

		lineShader.width = lineWidth;

		setColor(colorX);
		lineTo(size, 0, 0);

		setColor(colorY);
		moveTo(0, 0, 0);
		lineTo(0, size, 0);

		setColor(colorZ);
		moveTo(0, 0, 0);
		lineTo(0, 0, size);
	}
}

class GridHelper extends h3d.scene.Graphics {
	public function new( ?parent : Object, size = 10.0, divisions = 10, color1 = 0x444444, color2 = 0x888888, lineWidth = 1.0 ) {
		super(parent);

		material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");

		lineShader.width = lineWidth;

		var hsize = size / 2;
		var csize = size / divisions;
		var center = divisions / 2;
		for ( i in 0...divisions + 1 ) {
			var p = i * csize;
			setColor((i != 0 && i != divisions && i % center == 0) ? color2 : color1);
			moveTo(-hsize + p, -hsize, 0);
			lineTo(-hsize + p, -hsize + size, 0);
			moveTo(-hsize, -hsize + p, 0);
			lineTo(-hsize + size, -hsize + p, 0);
		}
	}
}
