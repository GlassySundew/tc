import dn.Rand;
import en.player.WebPlayer;
import net.Connect;
import hxd.System;
import h3d.pass.PassList;
import ui.Hud;
import en.player.Player;
import differ.math.Vector;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import h3d.scene.Scene;
import h3d.scene.Mesh;
import h3d.mat.Texture;
import h3d.scene.CameraController;
import dn.Process;
import hxd.Key;
import format.tmx.Data;
import format.tmx.*;
import hxd.Res;

class Game extends Process {
	public static var inst:Game;

	public var lvlName:String;
	public var ca:dn.heaps.Controller.ControllerAccess;
	public var camera:Camera;

	private var cam:CameraController;

	public var level:Level;

	var tmxMap:TmxMap;

	public var player:en.player.Player;

	private var tsx:Map<String, TmxTileset>;
	private var r:Reader;

	public var hud:Hud;
	public var fx:Fx;

	public function new() {
		super(Main.inst);
		inst = this;
		ca = Main.inst.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.inst.root, Const.DP_BG);

		camera = new Camera();
		// hud = new ui.Hud();

		startLevel("alphamap.tmx");
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

	public function startLevel(name:String) {
		// temp = null;

		engine.clear(0, 1);
		if (level != null) {
			level.destroy();
			for (e in Entity.ALL)
				e.destroy();
			gc();
		}

		tsx = new Map();
		r = new Reader();
		r.resolveTSX = getTSX;
		tmxMap = r.read(Xml.parse(Res.loader.load(Const.LEVELS_PATH + name).entry.getText()));
		level = new Level(tmxMap);

		CompileTime.importPackage("en");
		var entNames = (CompileTime.getAllClasses(Entity));

		#if hl
		var eregClass = ~/\$([a-z_0-9]+)+$/gi;
		#else
		var eregClass = ~/\.([a-z0-9]+)\n/gi; // регулярка для js, который, нахуй, не работает
		#end

		for (e in level.entities)
			for (nam in entNames) {
				if (eregClass.match('$nam'.toLowerCase()) && eregClass.matched(1) == e.name)
					Type.createInstance(nam, [e.x, e.y, e]);
			}

		player = Player.inst;

		// putting player inst to the last position of entities array as a depth sorting fix (хуйня ебаная на самом деле, но существует трудновоспроизводимый баг с
		// сортировкой, когда 2 объекта начаинают неправильно рисоваться при неопределенном положении в списке объектов в Tiled, если они расположены на соседних линиях в изометрии)

		applyTmxObjOnEnt();

		camera.target = player;
		camera.recenter();
		cd.unset("levelDone");
		// System.openURL("https://pornreactor.cc");

		// rect-obj position fix
		for (en in Entity.ALL)
			if (en.tmxObj != null)
				en.footY -= en.tmxObj.objectType == OTRectangle ? Const.GRID_HEIGHT : 0;

		// new Connect();
	}

	public function applyTmxObjOnEnt(?ent:Null<Entity>) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls

		// parsing collision objects from 'colls' tileset
		for (tileset in tmxMap.tilesets) {
			var ereg = ~/(^[^.]*)+/; // regexp to take tileset name
			if (ereg.match(tileset.source) && ereg.matched(1) == 'colls')
				for (tile in tileset.tiles) {
					var ereg = ~/\/([a-z_0-9]+)\./; // regexp to take string between last / and . from picture path
					if (ereg.match(tile.image.source)) {
						var ents = ent != null ? [ent] : Entity.ALL;
						for (ent in ents) {
							var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix
							if (tile.objectGroup != null
								&& eregClass.match('$ent'.toLowerCase())
								&& eregClass.matched(1) == ereg.matched(1)
								&& tile.objectGroup.objects.length > 0 /*&& ent.collisions.length == 0*/) {
								var centerSet = false;
								for (obj in tile.objectGroup.objects) {
									var params = {
										x: M.round(obj.x) + ent.footX,
										y: M.round(obj.y) + ent.footY,
										width: M.round(obj.width),
										height: M.round(obj.height)
									};
									var xCent = 0.;
									var yCent = 0.;

									switch (obj.objectType) {
										case OTEllipse:
											var shape = new differ.shapes.Circle(0, 0, params.width / 2);
											shape.scaleY = params.height / params.width;
											trace(obj.width, obj.height);
											xCent = M.round(obj.width / 2);
											yCent = M.round(obj.height / 2);

											ent.collisions.set(shape,
												{cent: new h3d.Vector(xCent, yCent), offset: new h3d.Vector(obj.x + xCent, -obj.y - yCent)});
										case OTRectangle:
											ent.collisions.set(Polygon.rectangle(params.x, params.y, params.width, params.height),
												{cent: new h3d.Vector(), offset: new h3d.Vector()});
										case OTPolygon(points):
											var verts:Array<Vector> = [];
											for (i in points) {
												verts.push(new Vector((i.x), (-i.y)));
											}
											var yArr = verts.copy();
											yArr.sort(function(a, b) return (a.y < b.y) ? -1 : ((a.y > b.y) ? 1 : 0));
											var xArr = verts.copy();
											xArr.sort(function(a, b) return (a.x < b.x) ? -1 : ((a.x > b.x) ? 1 : 0));
											checkPolyClockwise(verts);

											xCent = M.round((xArr[xArr.length - 1].x + xArr[0].x) * .5);
											yCent = -M.round((yArr[yArr.length - 1].y + yArr[0].y) * .5);
											var poly = new Polygon(0, 0, verts);
											poly.rotation = -obj.rotation;
											poly.name = Random.string(5);
											ent.collisions.set(poly, {cent: new h3d.Vector(xCent, -yCent), offset: new h3d.Vector(obj.x, -obj.y)});
											trace(obj.width, obj.height);
										default:
									}

									if (!centerSet) {
										ent.spr.setCenterRatio((M.round(obj.x + xCent)) / ent.spr.tile.width, (M.round(obj.y + yCent)) / ent.spr.tile.height);

										ent.footX += M.round((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width) - Const.GRID_WIDTH / 2;
										ent.footY -= (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height + Const.GRID_HEIGHT;

										centerSet = true;
									}
									try
										cast(ent, Interactive).rebuildInteract()
									catch (e:Dynamic)
										0;
								}
							}
						}
					}
				}
		}
	}

	private function getTSX(name:String):TmxTileset {
		var cached:TmxTileset = tsx.get(name);
		if (cached != null)
			return cached;
		cached = r.readTSX(Xml.parse(Res.loader.load(Const.LEVELS_PATH + name).entry.getText()));
		tsx.set(name, cached);
		return cached;
	}

	function gc() {
		if (Entity.GC == null || Entity.GC.length == 0)
			return;

		for (e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		for (e in Entity.ALL)
			e.destroy();
		gc();
	}

	override function update() {
		super.update();

		// Updates
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.preUpdate();
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.update();
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.postUpdate();
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.frameEnd();
		gc();

		if (!ui.Console.inst.isActive() && !ui.Modal.hasAny()) {
			// Exit
			if (ca.isKeyboardPressed(Key.X))
				if (!cd.hasSetS("exitWarn", 3))
					trace(Lang.t._("Press X again to exit."));
				else {
					#if (debug && hl)
					hxd.System.exit();
					#else
					destroy();
					#end
				}
			if (ca.selectPressed())
				restartLevel();
		}
	}
}
