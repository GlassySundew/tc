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
		hud = new ui.Hud();

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
		var data = r.read(Xml.parse(Res.loader.load('tiled/' + name).entry.getText()));
		level = new Level(data);
		CompileTime.importPackage("en");
		var entNames = (CompileTime.getAllClasses(Entity));

		#if hl
		var eregClass = ~/\$([a-z0-9]+)+$/gi;
		#else
		var eregClass = ~/\.([a-z0-9]+)\n/gi; // регулярка для js, который, нахуй, не работает
		#end

		for (e in level.entities)
			for (nam in entNames) {
				if (eregClass.match('$nam'.toLowerCase()) && eregClass.matched(1) == e.name)
					Type.createInstance(nam, [e.x, e.y, e]);
			}

		player = Player.inst;
		// putting player inst to the last position of entities array as a depth sorting fix
		// Entity.ALL.remove(player);
		// Entity.ALL.insert(0, player);

		// parsing collision objects from 'colls' tileset
		for (tileset in data.tilesets) {
			var ereg = ~/(^[^.]*)+/; // regexp to take tileset name
			if (ereg.match(tileset.source) && ereg.matched(1) == 'colls')
				for (tile in tileset.tiles) {
					var ereg = ~/\/([a-z0-9]+)\./; // regexp to take string between last / and . from picture path
					if (ereg.match(tile.image.source)) {
						for (ent in Entity.ALL) {
							var eregClass = ~/\.([a-z0-9]+)+$/gi; // regexp to remove 'en.' prefix
							if (tile.objectGroup != null
								&& eregClass.match('$ent'.toLowerCase())
								&& eregClass.matched(1) == ereg.matched(1)
								&& tile.objectGroup.objects.length >= 0
								&& ent.collisions.length == 0) {
								for (obj in tile.objectGroup.objects) {
									var params = {
										x: M.round(obj.x) + ent.footX,
										y: M.round(obj.y) + ent.footY,
										width: M.round(obj.width),
										height: M.round(obj.height)
									};
									var xCent = 0.;
									var yCent = 0.;

									var shape:Circle = null;
									switch (obj.objectType) {
										case OTEllipse:
											shape = new differ.shapes.Circle(0, 0, params.width / 2);
											shape.scaleY = params.height / params.width;
											ent.collisions.push(shape);
										case OTRectangle:
											ent.collisions.push(Polygon.rectangle(params.x, params.y, params.width, params.height));
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

											xCent = ((xArr[xArr.length - 1].x + xArr[0].x) * .5);
											yCent = -((yArr[yArr.length - 1].y + yArr[0].y) * .5);
											var poly = new Polygon(0, 0, verts);
											poly.rotation = obj.rotation;
											ent.collisions.push(poly);
										default:
									}

									ent.spr.setCenterRatio((M.round(obj.x + xCent) + M.round((obj.width) / 2)) / ent.spr.tile.width,
										(M.round(obj.y + yCent) + M.round((obj.height) / 2)) / ent.spr.tile.height);

									ent.sprOffColX = xCent;
									ent.sprOffColY = -yCent;

									ent.footX += M.round((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width) - Const.GRID_WIDTH / 2;
									ent.footY -= (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height + Const.GRID_HEIGHT;
								}
							}
						}
					}
				}
		}

		// Boot.inst.s3d.camera = new h3d.Camera(25, 1, 1.777777778, 1);
		camera.target = player;
		camera.recenter();
		cd.unset("levelDone");

		// rect-obj position fix
		// for (en in Entity.ALL)
		// 	if (en.tmxObj != null)
		// 		en.sprOffY -= en.tmxObj.objectType == OTRectangle ? Const.GRID_HEIGHT : 0;
	}

	private function getTSX(name:String):TmxTileset {
		var cached:TmxTileset = tsx.get(name);
		if (cached != null)
			return cached;
		cached = r.readTSX(Xml.parse(Res.loader.load('tiled/' + name).entry.getText()));
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
