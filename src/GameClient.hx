import cherry.soup.EventSignal.EventSignal0;
import ui.PauseMenu;
import Level.StructTile;
import differ.math.Vector;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import dn.Process;
import en.Entity;
import en.player.Player;
import format.tmx.Data;
import h3d.scene.CameraController;
import h3d.scene.Object;
import net.ClientController;
import tools.Settings;
import ui.Hud;

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

	public var camera : s3d.Camera;

	private var cam : CameraController;

	public var sLevel : ServerLevel;

	var level : Level;

	public var tmxMap : TmxMap;

	public var player : en.player.Player;
	public var hud : Hud;
	public var fx : Fx;

	public var structTiles : Array<StructTile> = [];

	public var suspended : Bool = false;

	public var navFieldsGenerated : Null<Int>;

	var ca : ControllerAccess<ControllerAction>;

	public var onLevelChanged = new EventSignal0();

	#if game_tmod
	var stats : h2d.Text;
	#end

	public function new() {
		super( Main.inst );

		inst = this;

		ca = Main.inst.controller.createAccess();

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

		createRootInLayers( Main.inst.root, Const.DP_BG );

		camera = new s3d.Camera();
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

		delayer.addF(() -> {
			hideStrTiles();
			Process.resizeAll();
		}, 10 );

		// applyTmxObjOnEnt();

		targetCameraOnPlayer();

		onLevelChanged.dispatch();

		return level;
	}

	public function targetCameraOnPlayer() {
		camera.target = player;
		camera.recenter();
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

		Client.inst.disconnect();

		ca.dispose();
	}

	override function update() {
		super.update();

		#if game_tmod
		stats.text = "tmod: " + tmod;
		#end

		// Updates
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.preUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.update();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.postUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.frameEnd();
		gc();

		if ( ca.isPressed( Escape ) ) {

			new PauseMenu( this, Main.inst.root, Main.inst );
		}
	}

	public function applyTmxObjOnEnt( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		if ( tmxMap == null ) return;

		// parsing collision objects from 'colls' tileset
		var entitiesTs : TmxTileset = null;

		for ( tileset in tmxMap.tilesets ) {
			if ( tileset.source != null
				&& StringTools.contains( tileset.source, "entities" ) ) {
				entitiesTs = tileset;
				break;
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

									ent.collisions.set( shape, new differ.math.Vector( obj.x + cent.x, obj.y + cent.y ) );

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

	public function showStrTiles() {
		for ( i in structTiles ) i.visible = true;
	}

	public function hideStrTiles() {
		for ( i in structTiles ) i.visible = false;
	}

	override function pause() {
		super.pause();
	}

	override function resume() {
		super.resume();
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
			setColor( ( i != 0 && i != divisions && i % center == 0 ) ? color2 : color1 );
			moveTo(-hsize + p, -hsize, 0 );
			lineTo(-hsize + p, -hsize + size, 0 );
			moveTo(-hsize, -hsize + p, 0 );
			lineTo(-hsize + size, -hsize + p, 0 );
		}
	}
}
