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
import ui.PauseMenu;

// import tools.Save;

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

	public function new() {
		super(Main.inst);

		inst = this;
		ca = Main.inst.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.inst.root, Const.DP_BG);

		camera = new Camera();
	}

	public function onCdbReload() {}

	public function nextLevel() {
		/*
			if (level.data.getStr("nextLevel") != "")
					startLevel(level.data.getStr("nextLevel"));
				else {
					var ogmoProj = new ogmo.Project(hxd.Res.map.ld45, false);
				if (ogmoProj.getLevelByName("level" + (level.lid + 1)) == null)
				startLevel("level" + level.lid);
			else
				startLevel("level" + (level.lid + 1));
		}*/
	}

	public function restartLevel() {
		// startLevel(lvlName);
	}

	// по сути workaround, т.к. надо, чтобы тайлы сохранялись отдельно, вместо .tmx файла целиком
	// public function loadLevel(resolvedMap:) {
	// 	engine.clear(0, 1);
	// }

	public function startLevel( name : String, ?manual : Bool = false ) {

		// tmxMap = resolveMap(name);
		// startLevelFromParsedTmx(tmxMap, name);

		if ( level != null ) {
			var cachedLevel = Save.inst.saveLevel(level);
		}

		var levelFromCache = Save.inst.loadLevelByName(name.split(".")[0]);
		if ( levelFromCache == null ) {
			tmxMap = resolveMap(name);
			startLevelFromParsedTmx(tmxMap, name, manual);

			var cachedPlayer = Save.inst.playerSavedOn(level);
			if ( cachedPlayer != null ) {
				Save.inst.loadEntity(cachedPlayer);
				player = Player.inst;
				targetCameraOnPlayer();
			}
		} else {
			level = levelFromCache;
		}
	}

	public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String, ?manual : Bool = false ) {
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
		Save.inst.bringPlayerToLevel(Save.inst.saveLevel(level));

		// Entity spawning
		CompileTime.importPackage("en");
		var entClasses = (CompileTime.getAllClasses(Entity));

		// Search for name from parsed entNames Entity classes and spawns it, creates static SpriteEntity and puts name into spr group if not found
		function searchAndSpawnEnt( e : TmxObject ) {
			var isoX = 0., isoY = 0.;
			if ( tmxMap.orientation == Isometric ) {
				// все объекты в распаршенных слоях уже с конвертированными координатами
				// entities export lies ahead
				isoX = Level.inst.cartToIsoLocal(e.x, e.y).x;
				isoY = Level.inst.cartToIsoLocal(e.x, e.y).y;
			}

			// Парсим все классы - наследники en.Entity и спавним их
			for ( eClass in entClasses ) {
				eregCompTimeClass.match('$eClass'.toLowerCase());
				if ( eregCompTimeClass.match('$eClass'.toLowerCase()) && eregCompTimeClass.matched(1) == e.name ) {
					Type.createInstance(eClass, [isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, e]);
					return;
				}
			}
			// если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
			switch( e.objectType ) {
				case OTTile(gid):
					var objGid = Tools.getTileByGid(tmxMap, gid);
					if ( objGid != null ) {
						var source = objGid.image.source;
						if ( eregFileName.match(source) ) {
							new SpriteEntity(isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, eregFileName.matched(1), e);
							return;
						}
					}
				default:
			}
		}
		// Загрузка игрока при переходе в другую локацию
		var cachedPlayer = Save.inst.playerSavedOn(level);

		if ( cachedPlayer != null ) {
			for ( e in level.entities ) if ( manual || e.name != "player" ) searchAndSpawnEnt(e);
			// Save.inst.loadEntity(cachedPlayer);
		} else
			for ( e in level.entities ) searchAndSpawnEnt(e);

		// if ( manual && Player.inst != null ) {
		// 	trace("zhopa
		// 	");

		// 	var playerObj = level.entities.filter(e -> e.name == "player")[0];
		// 	Player.inst.footX = playerObj.x;
		// 	Player.inst.footY = playerObj.y;
		// }
		applyTmxObjOnEnt();

		player = Player.inst;
		targetCameraOnPlayer();

		delayer.addF(() -> {
			hideStrTiles();
		}, 2);

		return level;
	}

	public function targetCameraOnPlayer() {
		camera.target = player;
		camera.recenter();
	}

	public function applyTmxObjOnEnt( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		// parsing collision objects from 'colls' tileset
		for ( tileset in tmxMap.tilesets ) {
			if ( StringTools.contains(tileset.source, "entities") ) for ( tile in tileset.tiles ) {
				if ( eregFileName.match(tile.image.source) ) {
					var ents = ent != null ? [ent] : Entity.ALL;
					for ( ent in ents ) {
						if ( (tile.objectGroup != null && eregClass.match('$ent'.toLowerCase()))
							&& (((eregClass.matched(1) == eregFileName.matched(1) || ent.spr.groupName == eregFileName.matched(1))
								&& tile.objectGroup.objects.length > 0
								|| (Std.isOfType(ent, SpriteEntity)
									&& eregFileName.matched(1) == ent.spr.groupName))) /*&& ent.collisions.length == 0*/ ) {
							var centerSet = false;

							for ( obj in tile.objectGroup.objects ) { // Засовываем объекты для детекта коллизий по Entity
								var params = {
									x : M.round(obj.x) + ent.footX,
									y : M.round(obj.y) + ent.footY,
									width : M.round(obj.width),
									height : M.round(obj.height)
								};
								var xCent = 0.;
								var yCent = 0.;
								function unsetCenter() {
									ent.footX -= ((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width);
									ent.footY += (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height;
								}
								function getCenterPivot() : h3d.Vector {
									var pivotX = ((obj.x + xCent)) / ent.spr.tile.width;
									var pivotY = ((obj.y + yCent)) / ent.spr.tile.height;
									// pivotX = (ent.tmxObj != null && ent.tmxObj.flippedHorizontally) ? 1 - pivotX : pivotX;
									pivotY = (ent.tmxObj != null && ent.tmxObj.flippedVertically) ? 1 - pivotY : pivotY;
									return new h3d.Vector(pivotX, pivotY);
								}
								function setCenter() {
									var center = getCenterPivot();

									if ( obj.name == "center" ) {
										ent.mesh.xOff = -(center.x - ent.spr.pivot.centerFactorX) * ent.spr.tile.width;
										ent.mesh.yOff = (center.y - ent.spr.pivot.centerFactorY) * ent.spr.tile.height;
										#if depth_debug
										ent.mesh.renewDebugPts();
										#end
									}

									ent.spr.setCenterRatio(center.x, center.y);
								}

								switch( obj.objectType ) {
									case OTEllipse:
										var shape = new differ.shapes.Circle(0, 0, params.width / 2);
										shape.scaleY = params.height / params.width;
										xCent = M.round(obj.width / 2);
										yCent = M.round(obj.height / 2);
										ent.collisions.set(shape,
											{ cent : new h3d.Vector(xCent, yCent), offset : new h3d.Vector(obj.x + xCent, -obj.y - yCent) });
									case OTRectangle:
										// Точка парсится как OTRectangle, точка с названием center будет обозначать центр

										ent.collisions.set(Polygon.rectangle(params.x, params.y, params.width, params.height),
											{ cent : new h3d.Vector(), offset : new h3d.Vector() });
									case OTPolygon(points):
										var cents = getProjectedDifferPolygonRect(obj, points);
										xCent = cents.x;
										yCent = cents.y;

										var pts = checkPolyClockwise(points);
										var verts : Array<Vector> = [];
										for ( i in pts ) verts.push(new Vector((i.x), (-i.y)));

										var poly = new Polygon(0, 0, verts);
										poly.rotation = -obj.rotation;

										// vertical flipping
										// if ( ent.tmxObj != null && ent.tmxObj.flippedHorizontally ) poly.scaleX = -1;
										if ( ent.tmxObj != null && ent.tmxObj.flippedVertically ) poly.scaleY = -1;

										var xOffset = /*poly.scaleX < 0 ? ent.spr.tile.width - obj.x :*/ obj.x;
										var yOffset = -obj.y;
										ent.collisions.set(poly, { cent : new h3d.Vector(xCent, -yCent), offset : new h3d.Vector(xOffset, yOffset) });
									case OTPoint:
										if ( obj.name == "center" ) {
											if ( centerSet ) unsetCenter();
											setCenter();
											ent.offsetFootByCenter();
											centerSet = true;
										}
									default:
								}

								if ( !centerSet ) {
									setCenter();
									ent.offsetFootByCenter();

									centerSet = true;
								} else {
									var center = getCenterPivot();
									if ( obj.name != "center" ) {
										ent.mesh.xOff = (center.x - ent.spr.pivot.centerFactorX) * ent.spr.tile.width;
										ent.mesh.yOff = -(center.y - ent.spr.pivot.centerFactorY) * ent.spr.tile.height;
									}
								}
							}
							try {
								cast(ent, Interactive).rebuildInteract();
							}
							catch( e:Dynamic ) {}
							// if ( ent.tmxObj != null && ent.tmxObj.flippedHorizontally && ent.mesh.isLong ) ent.mesh.flipX();

							if ( Std.isOfType(ent, SpriteEntity) && tile.properties.exists("interactable") ) {
								cast(ent, SpriteEntity).interactable = tile.properties.getBool("interactable");
							}
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
