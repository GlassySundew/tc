import h3d.Engine;
import en.player.Player;
import differ.shapes.Polygon;
import cherry.soup.EventSignal.EventSignal0;
import differ.math.Vector;
import differ.shapes.Circle;
import dn.Process;
import format.tmx.Data;
import format.tmx.*;
import hxd.Res;

class GameServer extends Process implements GameAble {
	public static var inst : GameServer;

	public var network(get, never) : Bool;

	inline function get_network() return false;

	public var lvlName : String;
	public var level : Level;

	public var tmxMap : TmxMap;

	public var tmxMapOg : TmxMap;

	public var player : en.player.Player;

	public var execAfterLvlLoad : EventSignal0;

	public function new() {
		super();
		inst = this;

		#if( hl && pak )
		hxd.Res.initPak();
		#elseif( hl )
		hxd.Res.initLocal();
		#end

		Assets.init();
		Data.load(hxd.Res.data.entry.getText());
		startLevel("server_test.tmx");
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

	public function startLevel(name : String) {
		engine.clear(0, 1);
		execAfterLvlLoad = new EventSignal0();
		if ( level != null ) {
			level.destroy();
			for (e in Entity.ALL) e.destroy();
			gc();
		}
		tmxMap = resolveMap(name);

		level = new Level(tmxMap);
		lvlName = name.split('.')[0];

		// Entity spawning
		CompileTime.importPackage("en");

		var entClasses = (CompileTime.getAllClasses(Entity));

		// Search for name from parsed entNames Entity classes and spawns it, creates static SpriteEntity and puts name into spr group if not found
		function searchAndSpawnEnt(e : TmxObject) {
			var isoX = 0., isoY = 0.;
			if ( tmxMap.orientation == Isometric ) {
				// все объекты в распаршенных слоях уже с конвертированными координатами
				// entities export lies ahead
				isoX = Level.inst.cartToIsoLocal(e.x, e.y).x;
				isoY = Level.inst.cartToIsoLocal(e.x, e.y).y;
			}

			// Парсим все классы - наследники en.Entity и спавним их
			for (eClass in entClasses) {
				eregCompTimeClass.match('$eClass'.toLowerCase());
				if ( e.name == "player" ) {
					tmxMap.properties.setFloat("playerX", isoX);
					tmxMap.properties.setFloat("playerY", isoY);
					return;
				} else if ( eregCompTimeClass.match('$eClass'.toLowerCase()) && eregCompTimeClass.matched(1) == e.name ) {
					Type.createInstance(eClass, [isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, e]);
					return;
				}
			}
			switch( e.objectType ) {
				case OTTile(gid):
					var source = Tools.getTileByGid(tmxMap, gid).image.source;
					if ( eregFileName.match(source) ) {
						new SpriteEntity(isoX != 0 ? isoX : e.x, isoY != 0 ? isoY : e.y, eregFileName.matched(1), e);
						return;
					}
				default:
			}
		}
		for (e in level.entities) searchAndSpawnEnt(e);

		applyTmxObjOnEnt();

		// player = Player.inst;

		// rect-obj position fix
		for (en in Entity.ALL) if ( en.tmxObj != null ) en.footY -= en.tmxObj.objectType == OTRectangle ? Const.GRID_HEIGHT : 0;

		// new AxesHelper(Boot.inst.s3d);
		// new GridHelper(Boot.inst.s3d, 10, 10);
	}

	public function applyTmxObjOnEnt(?ent : Null<Entity>) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		// parsing collision objects from 'colls' tileset
		for (tileset in tmxMap.tilesets) {
			var ereg = ~/(^[^.]*)+/; // regexp to take tileset name
			if ( ereg.match(tileset.source) && ereg.matched(1) == 'colls' ) for (tile in tileset.tiles) {
				if ( eregFileName.match(tile.image.source) ) {
					var ents = ent != null ? [ent] : Entity.ALL;
					for (ent in ents) {
						if ( (tile.objectGroup != null && eregClass.match('$ent'.toLowerCase()))
							&& ((eregClass.matched(1) == eregFileName.matched(1)
								&& tile.objectGroup.objects.length > 0
								|| (Std.isOfType(ent, SpriteEntity)
									&& eregFileName.matched(1) == ent.spr.groupName))) /*&& ent.collisions.length == 0*/ ) {
							var centerSet = false;
							for (obj in tile.objectGroup.objects) { // Засовываем объекты для детекта коллизий по Entity
								var params = {
									x : M.round(obj.x) + ent.footX,
									y : M.round(obj.y) + ent.footY,
									width : M.round(obj.width),
									height : M.round(obj.height)
								};
								var xCent = 0.;
								var yCent = 0.;
								function unsetCenter() {
									ent.footX -= M.round((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width);
									ent.footY += (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height;
								}

								function setCenter() {
									var pivotX = ((obj.x + xCent)) / ent.spr.tile.width;
									var pivotY = ((obj.y + yCent)) / ent.spr.tile.height;
									pivotX = (ent.tmxObj != null && ent.tmxObj.flippedVertically) ? 1 - pivotX : pivotX;

									ent.spr.setCenterRatio(pivotX, pivotY);
									ent.footX += M.round((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width);
									ent.footY -= (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height;
								}
								switch( obj.objectType ) {
									case OTEllipse:
										var shape = new differ.shapes.Circle(0, 0, params.width / 2);
										shape.scaleY = params.height / params.width;
										xCent = M.round(obj.width / 2);
										yCent = M.round(obj.height / 2);
										ent.collisions.set(shape,
											{cent : new h3d.Vector(xCent, yCent), offset : new h3d.Vector(obj.x + xCent, -obj.y - yCent)});
									case OTRectangle:
										// Точка парсится как OTRectangle, точка с названием center будет обозначать центр

										ent.collisions.set(Polygon.rectangle(params.x, params.y, params.width, params.height),
											{cent : new h3d.Vector(), offset : new h3d.Vector()});
									case OTPolygon(points):
										var pts = checkPolyClockwise(points);
										var verts : Array<Vector> = [];
										for (i in pts) {
											verts.push(new Vector((i.x), (-i.y)));
										}
										var yArr = verts.copy();
										yArr.sort(function(a, b) return (a.y < b.y) ? -1 : ((a.y > b.y) ? 1 : 0));
										var xArr = verts.copy();
										xArr.sort(function(a, b) return (a.x < b.x) ? -1 : ((a.x > b.x) ? 1 : 0));

										// xCent и yCent - половины ширины и высоты неповёрнутого полигона соответственно
										xCent = M.round((xArr[xArr.length - 1].x + xArr[0].x) * .5);
										yCent = -M.round((yArr[yArr.length - 1].y + yArr[0].y) * .5);

										// c - радиус от начальной точки поли до центра поли
										var c = Math.sqrt(M.pow(xCent, 2) + M.pow(yCent, 2));
										// alpha - угол между начальной точкой неповёрнутого полигона и центром полигона
										var alpha = Math.atan(yCent / xCent);

										// xCent и yCent в данный момент - проекции отрезка, соединяющего начальную точку полигона и центр полигона на оси x и y соответственно
										yCent = -c * (Math.sin(M.toRad(-obj.rotation) - alpha));
										xCent = c * (Math.cos(M.toRad(-obj.rotation) - alpha));

										var poly = new Polygon(0, 0, verts);
										poly.rotation = -obj.rotation;

										// vertical flipping
										if ( ent.tmxObj != null && ent.tmxObj.flippedVertically ) poly.scaleX = -1;
										var xOffset = poly.scaleX < 0 ? ent.spr.tile.width - obj.x : obj.x;
										var yOffset = -obj.y;
										ent.collisions.set(poly, {cent : new h3d.Vector(xCent, -yCent), offset : new h3d.Vector(xOffset, yOffset)});
									case OTPoint:
										if ( obj.name == "center" ) {
											if ( centerSet ) unsetCenter();
											setCenter();
											centerSet = true;
										}
									default:
								}

								if ( !centerSet ) {
									setCenter();
									centerSet = true;
								} else {
									var pivotX = ((obj.x + xCent)) / ent.spr.tile.width;
									var pivotY = ((obj.y + yCent)) / ent.spr.tile.height;
									pivotX = (ent.tmxObj != null && ent.tmxObj.flippedVertically) ? 1 - pivotX : pivotX;
									#if depth_debug
									#end
								}
							}
							if ( Std.is(ent, SpriteEntity) && tile.properties.exists("interactable") ) {
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

	function gc() {
		if ( Entity.GC == null || Entity.GC.length == 0 ) return;

		for (e in Entity.GC) e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		for (e in Entity.ALL) e.destroy();
		gc();
	}

	override function update() {
		super.update();

		// Updates
		for (e in Entity.ALL) if ( !e.destroyed ) e.preUpdate();
		for (e in Entity.ALL) if ( !e.destroyed ) e.update();
		for (e in Entity.ALL) if ( !e.destroyed ) e.postUpdate();
		for (e in Entity.ALL) if ( !e.destroyed ) e.frameEnd();
		gc();
	}
}
