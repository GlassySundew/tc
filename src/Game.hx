import differ.shapes.Polygon;
import h3d.scene.Scene;
import h3d.scene.Mesh;
import h3d.mat.DepthBuffer;
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

	public var scroller:h2d.Layers;
	public var level:Level;

	public var player:en.player.Player;

	private var tsx:Map<String, TmxTileset>;
	private var r:Reader;

	public function new() {
		super(Main.inst);
		inst = this;
		ca = Main.inst.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.inst.root, Const.DP_BG);

		scroller = new h2d.Layers();
		scroller.visible = false;

		root.add(scroller, Const.DP_BG);
		// Boot.inst.s3d.camera.setFovX(60, 1.777777778);
		Boot.inst.s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);

		// cam = new h3d.scene.CameraController(Boot.inst.s3d);
		// cam.loadFromCamera();
		// Boot.inst.s3d.addChild(cam);

		camera = new Camera();
		startLevel("alphamap.tmx");
	}

	public function onCdbReload() {}

	public function nextLevel() { /*
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
		// s3d.camera.pos = new Vector(0, -0.0000001, 0);

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

		for (e in level.getEntities("rock"))
			new en.Rock(e.x, e.y);

		var pt = level.getEntityPt("player");
		player = new en.player.Player(pt.cx, pt.cy);

		for (tileset in data.tilesets) { // applying hitboxes from 'colls' tileset
			var ereg = ~/(^[^.]*)+/; // regexp to take tileset name
			if (ereg.match(tileset.source) && ereg.matched(1) == 'colls')
				for (tile in tileset.tiles) {
					var ereg = ~/\/([a-z0-9_\.-]+)\./; // regexp to take string between last / and . from picture path
					if (ereg.match(tile.image.source)) {
						for (ent in Entity.ALL) {
							var eregClass = ~/\.([a-z0-9]+)+$/gi; // regexp to remove 'en.' prefix
							if (eregClass.match('$ent'.toLowerCase())
								&& eregClass.matched(1) == ereg.matched(1)
								&& tile.objectGroup.objects.length >= 0
								&& ent.collisions.length == 0) {
								for (obj in tile.objectGroup.objects) {
									var params = {
										x: obj.x + ent.footX,
										y: obj.y + ent.footY,
										width: obj.width,
										height: obj.height
									};
									switch (obj.objectType) {
										case OTEllipse:
											var shape = new differ.shapes.Circle(0, 0, params.width / 2);
											shape.scaleY = params.height / params.width;

											ent.collisions.push(shape);
										case OTRectangle:
											ent.collisions.push(Polygon.rectangle(params.x, params.y, params.width, params.height));
										default:
									}
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
