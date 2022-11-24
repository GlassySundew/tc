package game.client;

import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import dn.heaps.input.ControllerAccess;
import en.Entity;
import en.player.Player;
import format.tmx.TmxMap;
import game.client.level.Level;
import game.server.ServerLevel;
import h3d.scene.CameraController;
import h3d.scene.Object;
import net.Client;
import ui.PauseMenu;
import utils.Const;
import utils.threeD.CameraProcess;
import utils.tools.Settings;

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

	public function new( manual = false, acceptTmxPlayerCoord = false, acceptSqlPlayerCoord = false ) {
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

	public var cameraProc : CameraProcess;

	private var cam : CameraController;

	public var sLevel : ServerLevel;

	var level : Level;

	public var tmxMap : TmxMap;

	public var player : en.player.Player;

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

		#if game_tmod
		stats = new Text( Assets.fontPixel, Boot.inst.s2d );
		#end

		createRootInLayers( Main.inst.root, Const.DP_BG );

		cameraProc = new CameraProcess( this );
	}

	public function onCdbReload() {}

	public function restartLevel() {
		// startLevel(lvlName);
	}

	public function startLevelFromParsedTmx( tmxMap : TmxMap, name : String ) {
		this.tmxMap = tmxMap;
		engine.clear( 0, 1 );

		if ( level != null ) {
			level.destroy();
			gc();
		}
		level = new Level( tmxMap );

		// получаем sql id для уровня
		// var loadedLevel = Save.inst.saveLevel(level);

		hideStrTiles();

		onLevelChanged.dispatch();

		return level;
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

		if ( cameraProc != null ) cameraProc.destroy();
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

		if ( level != null ) level.world.step( Boot.inst.deltaTime );

		for ( e in Entity.ALL ) if ( !e.destroyed ) e.postUpdate();
		for ( e in Entity.ALL ) if ( !e.destroyed ) e.frameEnd();

		gc();

		if ( ca.isPressed( Escape ) ) {
			new PauseMenu( this, Main.inst.root, Main.inst );
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
