import ui.PauseMenu;
import MainMenu.TextButton;
import h2d.Text;
import h2d.Flow;
import Level.StructTile;
import Message.MapLoad;
import Message.PlayerInit;
import cherry.soup.EventSignal.EventSignal0;
import differ.math.Vector;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import dn.Process;
import en.player.Player;
import format.tmx.Data;
import h3d.scene.CameraController;
import tools.Settings;

class GameClient extends Process implements IGame {
	// static var HOST = "0.0.0.0";
	static var HOST = "78.24.222.152";
	static var PORT = 6676;

	public var network(get, never) : Bool;

	inline function get_network() return false;

	public static var inst : GameClient;

	public var lvlName : String;
	public var ca : dn.heaps.Controller.ControllerAccess;
	public var camera : Camera;

	private var cam : CameraController;

	public var level : Level;

	public var tmxMap : TmxMap;

	public var host : hxd.net.SocketHost;
	public var event : hxd.WaitEvent;
	public var uid : Int;
	public var player : en.player.Player;

	public var structTiles : Array<StructTile> = [];
	public var execAfterLvlLoad : EventSignal0 = new EventSignal0();

	public function new() {
		super(Main.inst);
		inst = this;

		ca = Main.inst.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.inst.root, Const.DP_BG);
		camera = new Camera();
		// hud = new ui.Hud();

		event = new hxd.WaitEvent();
		host = new hxd.net.SocketHost();
		host.setLogger(function ( msg ) trace(msg));
		uid = 1 + Std.random(1000);
		host.connect(HOST, PORT, function ( b ) {
			if ( !b ) {
				var infoFlow = new Flow(Boot.inst.s2d);
				infoFlow.verticalAlign = Middle;
				var textInfo = new Text(Assets.fontPixel, infoFlow);
				textInfo.text = "Server is down, stay tuned... ";
				var mainMenuBut : TextButton = null;
				mainMenuBut = new TextButton("return back to menu", ( e ) -> {
					mainMenuBut.cursor = Default;
					infoFlow.remove();
					destroy();
					new MainMenu(Boot.inst.s2d);
				}, infoFlow);

				trace("Failed to connect to server");
				return;
			}
			trace("Connected to server");

			host.sendTypedMessage(new PlayerInit(uid, Settings.params.nickname));

			// sys.thread.Thread.create(() -> {
			// 	while( true ) {
			// 		Sys.sleep(100);
			// 		try {
			// 			host.sendMessage({type: "ping", msg: uid});
			// 		}
			// 		catch( e:Dynamic ) {
			// 			break;
			// 		}
			// 	}
			// });
		});
		host.onTypedMessage(( c, msg : Message ) -> {
			switch( msg.type ) {
				case mapLoad:
					var map = cast(msg, MapLoad);
					loadMap(map.map);
				default:
			}
		});
		// host.onMessage = function(c, msg:Message) {
		// 	switch( msg.type ) {
		// 		case mapLoad:
		// 			var map = cast(msg, MapLoad);
		// 			loadMap(map.map);
		// 			trace("ZHOPA");

		// 		default:
		// 	}
		// }

		host.onUnregister = function ( o ) {};

		if ( player != null ) {}

		@:privateAccess Main.inst.onClose.add(() -> {
			try {
				player.destroy();
				host.unregister(player);
			}
			catch( e:Dynamic ) {
				trace("error occured while cursor disposing: " + e);
			}
			host.flush();
		});
	}

	public function loadMap( tmx : TmxMap ) {
		if ( level != null ) {
			level.destroy();
			for ( e in Entity.ALL ) e.destroy();
			gc();
		}
		tmxMap = tmx;
		level = new Level(tmxMap);

		// Entity spawning
		// CompileTime.importPackage("en");
		// var entClasses = (CompileTime.getAllClasses(Entity));

		// // Search for name from parsed entNames Entity classes and spawns it, creates static SpriteEntity and puts name into spr group if not found
		// function searchAndSpawnEnt(e : TmxObject) {
		// 	// Парсим все классы - наследники en.Entity и спавним их
		// 	for (eClass in entClasses) {
		// 		eregCompTimeClass.match('$eClass'.toLowerCase());
		// 		if ( eregCompTimeClass.match('$eClass'.toLowerCase()) && eregCompTimeClass.matched(1) == e.name ) {
		// 			Type.createInstance(eClass, [e.x, e.y, e]);
		// 			return;
		// 		}
		// 	}
		// 	switch( e.objectType ) {
		// 		case OTTile(gid):
		// 			var source = Tools.getTileByGid(tmxMap, gid).image.source;
		// 			if ( eregFileName.match(source) ) {
		// 				new SpriteEntity(e.x, e.y, eregFileName.matched(1), e);
		// 				return;
		// 			}
		// 		default:
		// 	}
		// }
		// for (e in level.entities) searchAndSpawnEnt(e);

		// applyTmxObjOnEnt();

		player = Player.inst;

		camera.target = player;
		camera.recenter();
	}

	public function applyTmxObjOnEnt( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		// parsing collision objects from 'colls' tileset
		for ( tileset in tmxMap.tilesets ) {
			var ereg = ~/(^[^.]*)+/; // regexp to take tileset name
			if ( ereg.match(tileset.source) && ereg.matched(1) == 'colls' ) for ( tile in tileset.tiles ) {
				if ( eregFileName.match(tile.image.source) ) {
					var ents = ent != null ? [ent] : Entity.ALL;
					for ( ent in ents ) {
						if ( (tile.objectGroup != null && eregClass.match('$ent'.toLowerCase()))
							&& ((eregClass.matched(1) == eregFileName.matched(1)
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
									ent.footX -= M.round((ent.spr.pivot.centerFactorX - .5) * ent.spr.tile.width);
									ent.footY += (ent.spr.pivot.centerFactorY) * ent.spr.tile.height - ent.spr.tile.height;
								}

								function setCenter() {
									var pivotX = ((obj.x + xCent)) / ent.spr.tile.width;
									var pivotY = ((obj.y + yCent)) / ent.spr.tile.height;
									pivotX = (ent.tmxObj != null && ent.tmxObj.flippedVertically) ? 1 - pivotX : pivotX;
									if ( obj.name == "center" ) {
										ent.mesh.xOff = -(pivotX - ent.spr.pivot.centerFactorX) * ent.spr.tile.width;
										ent.mesh.yOff = (pivotY - ent.spr.pivot.centerFactorY) * ent.spr.tile.height;
										#if depth_debug
										ent.mesh.renewDebugPts();
										#end
									}

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
										for ( i in pts ) {
											verts.push(new Vector((i.x), (-i.y)));
										}
										var yArr = verts.copy();
										yArr.sort(function ( a, b ) return (a.y < b.y) ? -1 : ((a.y > b.y) ? 1 : 0));
										var xArr = verts.copy();
										xArr.sort(function ( a, b ) return (a.x < b.x) ? -1 : ((a.x > b.x) ? 1 : 0));

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
									ent.mesh.xOff = (pivotX - ent.spr.pivot.centerFactorX) * ent.spr.tile.width;
									ent.mesh.yOff = -(pivotY - ent.spr.pivot.centerFactorY) * ent.spr.tile.height;
									#if depth_debug
									ent.mesh.renewDebugPts();
									#end
								}
							}
							try
								cast(ent, Interactive).rebuildInteract()
							catch( e:Dynamic ) {}
							if ( ent.tmxObj != null && ent.tmxObj.flippedVertically && ent.mesh.isLong ) ent.mesh.flipX();
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

	function gc() {
		if ( Entity.GC == null || Entity.GC.length == 0 ) return;

		for ( e in Entity.GC ) e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		inst = null;

		if ( camera != null ) camera.destroy();
		for ( e in Entity.ALL ) e.destroy();
		gc();

		if ( PauseMenu.inst != null ) PauseMenu.inst.destroy();
	}

	override function update() {
		super.update();

		// Updates
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.preUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.update();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.postUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.frameEnd();
		gc();

		host.flush();
	}

	public function showStrTiles() {
		for ( i in structTiles ) i.visible = true;
	}

	public function hideStrTiles() {
		for ( i in structTiles ) i.visible = false;
	}
}
