import haxe.CallStack;
import net.ClientController;
import en.Entity;
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
import haxe.Unserializer;
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

/**
	Логика игры на клиете
**/
class GameClient extends Process {
	public static var inst : GameClient;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var camera : Camera;

	private var cam : CameraController;

	public var sLevel : ServerLevel;

	var level : Level;

	public var tmxMap : TmxMap;

	public var player : en.player.Player;
	public var hud : Hud;
	public var fx : Fx;

	public var structTiles : Array<StructTile> = [];

	public var suspended : Bool = false;
	public var pauseCycle : Bool = false;

	public var navFieldsGenerated : Null<Int>;

	public var clientController : ClientController;

	#if game_tmod
	var stats : h2d.Text;
	#end

	public function new() {
		super( Main.inst );

		inst = this;

		// generating initial asteroids to have where to put player on
		// we do not yet have need to save stuff about asteroids, temporal clause

		// @:privateAccess
		// Navigation.fields.push(new NavigationField(
		// 	seed,
		// 	0,
		// 	0
		// ));

		// new Navigation(
		// 	Const.jumpReach,
		// 	'${GameClient.inst.seed}'
		// );

		#if game_tmod
		stats = new Text( Assets.fontPixel, Boot.inst.s2d );
		#end

		ca = Main.inst.controller.createAccess( "game" );
		ca.setLeftDeadZone( 0.2 );
		ca.setRightDeadZone( 0.2 );

		createRootInLayers( Main.inst.root, Const.DP_BG );

		camera = new Camera();
	}

	public function onCdbReload() {}

	public function restartLevel() {
		// startLevel(lvlName);
	}

	public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String ) {
		this.tmxMap = tmxMap;
		engine.clear( 0, 1 );

		trace( "creating level" );
		if ( level != null ) {
			trace( "destroying level" );
			level.destroy();
			gc();
		}
		level = new Level( tmxMap );

		// получаем sql id для уровня
		// var loadedLevel = Save.inst.saveLevel(level);

		// Entity spawning
		CompileTime.importPackage( "en" );
		var entClasses = CompileTime.getAllClasses( Entity );

		// Загрузка игрока при переходе в другую локацию
		// Save.inst.bringPlayerToLevel(loadedLevel);
		// var cachedPlayer = Save.inst.playerSavedOn(level);

		// if ( cachedPlayer != null ) {
		// 	// это значит, что инстанс игрока был ранее создан и делать нового не надо
		// 	for ( e in level.entities ) if ( playerLoadConf.manual
		// 		|| (
		// 			!e.properties.existsType("className", PTString)
		// 			|| e.properties.getString("className") != "en.player.$Player"
		// 		) ) {
		// 			searchAndSpawnEnt(e, entClasses);
		// 	}
		// 	Save.inst.loadEntity(cachedPlayer);
		// } else {
		// 	for ( e in level.entities )
		// 		searchAndSpawnEnt(e, entClasses);
		// }

		// player = Player.inst;

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

		// 		targetCameraOnPlayer();
		// 	}, 1);
		// }

		// if ( playerLoadConf.acceptSqlPlayerCoord ) {
		// 	delayer.addF(() -> {
		// 		var playerEnt = Save.inst.getPlayerShallowFeet(player);
		// 		if ( playerEnt != null ) {
		// 			var blob = '${playerEnt.blob}'.split("_");
		// 			player.setFeetPos(Std.parseInt(blob[0]), Std.parseInt(blob[1]));
		// 		}
		// 		targetCameraOnPlayer();
		// 	}, 1);
		// }

		delayer.addF(() -> {
			hideStrTiles();
			Process.resizeAll();
		}, 10 );

		// applyTmxObjOnEnt();

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
			if ( StringTools.contains( tileset.source, "entities" ) ) {
				entitiesTs = tileset;
			}
		}

		var ents = ent != null ? [ent] : Entity.ALL;

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

					if ( entityName == picName
						|| ent.spr.groupName == picName ) {

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

									ent.collisions.set( shape,
										{
											cent : new differ.math.Vector( cent.x, cent.y ),
											offset : new differ.math.Vector( obj.x + cent.x, obj.y + cent.y )
										} );

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
										{
											cent : new differ.math.Vector( cent.x, cent.y ),
											offset : new differ.math.Vector( obj.x, obj.y )
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
						var pivotX = (center.x) / ent.tmxObj.width;
						var pivotY = (center.y) / ent.tmxObj.height;

						// ent.setPivot(pivotX, pivotY);

						var actualX = ent.tmxObj.width / 2;
						var actualY = ent.tmxObj.height;

						ent.footX -= actualX - pivotX * ent.tmxObj.width;
						ent.footY += actualY - pivotY * ent.tmxObj.height;

						#if depth_debug
						ent.mesh.renewDebugPts();
						#end

						try {
							cast(ent, Interactive).rebuildInteract();
						}
						catch( e:Dynamic ) {}

						if ( Std.isOfType( ent, SpriteEntity ) && tile.properties.exists( "interactable" ) ) {
							cast(ent, SpriteEntity).interactable = tile.properties.getBool( "interactable" );
						}
					}
				}
			}
		}
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
		// if ( Player.inst != null && Player.inst.holdItem != null ) Player.inst.holdItem.visible = false;
	}

	override function resume() {
		super.resume();
		// if ( Player.inst != null && Player.inst.holdItem != null ) Player.inst.holdItem.visible = true;
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

		delayer.addF( function () {
			root.visible = false;
			root.removeChildren();
		}, 1 );
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
		super( parent );

		material.props = h3d.mat.MaterialSetup.current.getDefaults( "ui" );

		lineShader.width = lineWidth;

		setColor( colorX );
		lineTo( size, 0, 0 );

		setColor( colorY );
		moveTo( 0, 0, 0 );
		lineTo( 0, size, 0 );

		setColor( colorZ );
		moveTo( 0, 0, 0 );
		lineTo( 0, 0, size );
	}
}

class GridHelper extends h3d.scene.Graphics {
	public function new( ?parent : Object, size = 10.0, divisions = 10, color1 = 0x444444, color2 = 0x888888, lineWidth = 1.0 ) {
		super( parent );

		material.props = h3d.mat.MaterialSetup.current.getDefaults( "ui" );

		lineShader.width = lineWidth;

		var hsize = size / 2;
		var csize = size / divisions;
		var center = divisions / 2;
		for ( i in 0...divisions + 1 ) {
			var p = i * csize;
			setColor( (i != 0 && i != divisions && i % center == 0) ? color2 : color1 );
			moveTo(-hsize + p, -hsize, 0 );
			lineTo(-hsize + p, -hsize + size, 0 );
			moveTo(-hsize, -hsize + p, 0 );
			lineTo(-hsize + size, -hsize + p, 0 );
		}
	}
}
