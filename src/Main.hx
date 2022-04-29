package;

import cherry.soup.EventSignal;
import dn.heaps.input.ControllerAccess;
import dn.heaps.input.Controller;
import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import en.player.Player;
import hxd.Key;
import tools.Save;
import tools.Settings;



/**
	client-side only
**/
@:publicFields
class Main extends Process {
	public static var inst : Main;

	public var console : ui.Console;
	public var controller : Controller<ControllerAction>;
	public var ca : ControllerAccess<ControllerAction>;
	public var onClose : EventSignal0;
	public var save : Save;

	public var onResizeEvent : EventSignal0 = new EventSignal0();

	public function new( s : h2d.Scene ) {
		super();

		inst = this;
		createRoot( s );

		// root.filter = new h2d.filter.ColorMatrix();

		#if( hl && pak )
		hxd.Res.initPak();
		#elseif( hl )
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		#end

		#if debug
		hxd.Res.data.watch( function () {
			delayer.cancelById( "cdb" );
			//
			delayer.addS( "cdb", function () {
				Data.load( hxd.Res.data.entry.getBytes().toString() );
				if ( GameClient.inst != null ) GameClient.inst.onCdbReload();
			}, 0.2 );
		} );
		#end

		Boot.inst.renderer = new CustomRenderer();
		Boot.inst.s3d.renderer = Boot.inst.renderer;
		Boot.inst.renderer.depthColorMap = hxd.Res.gradients.test.toTexture();
		Boot.inst.renderer.enableFXAA = false;
		Boot.inst.renderer.enableSao = false;

		Assets.init();
		Cursors.init();
		Lang.init( "en" );

		uiMap = MapCache.inst.get( "ui.tmx" );
		uiConf = uiMap.mapLayersByName();
		for ( i in uiConf ) {
			var window = i.getObjectByName( "window" );
			if ( window != null ) i.localBy( window );
		}

		Data.load( hxd.Res.data.entry.getText() );

		console = new ui.Console( Assets.fontPixel, s );

		controller = new Controller( ControllerAction );
		ca = controller.createAccess();

		controller.bindPadLStick4( MoveLeft, MoveRight, MoveUp, MoveDown );

		controller.bindKeyboard( MoveUp,	[Key.UP,	Key.W] );
		controller.bindKeyboard( MoveLeft,	[Key.LEFT,	Key.A] );
		controller.bindKeyboard( MoveDown,	[Key.DOWN,	Key.S] );
		controller.bindKeyboard( MoveRight,	[Key.RIGHT,	Key.D] );

		controller.bindKeyboard( Action, Key.E );
		controller.bindKeyboard( DropItem, Key.Q );
		controller.bindKeyboard( ToggleInventory, Key.TAB ); 
		controller.bindKeyboard( ToggleCraftingMenu, Key.C );

		controller.bindKeyboard( Escape, Key.ESCAPE );

		onClose = new EventSignal0();

		Settings.loadSettings();

		onClose.add(() -> {
			if ( Player.inst != null ) {
				Player.inst.saveSettings();
			}
			Settings.saveSettings();
		} );

		if ( Settings.params.fullscreen ) toggleFullscreen();

		@:privateAccess engine.window.onClose = function () {
			onClose.dispatch();
			return true;
		}

		delayer.addF( start, 1 );

		// var bmp = new Bitmap(Tile.fromColor(0xffffff, 256, 256), Boot.inst.s2d);
		// bmp.filter = new Shader(new CornersRounder());
	}

	function start() {
		new MainMenu( Boot.inst.s2d );
	}

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		s.displayMode = s.displayMode == Fullscreen ? Windowed : Fullscreen;
		Settings.params.fullscreen = s.displayMode == Fullscreen;
		#end
	}

	public function startGame( ?seed : String ) {
		if ( GameClient.inst != null ) {
			GameClient.inst.destroy();
			@:privateAccess Process._garbageCollector( Process.ROOTS );
		}

		new Client();
		// Client.inst.sendMessage(SaveSystemOrder(CreateNewSave()));

		new GameClient();
	}

	public function connect( ?seed : String ) {
		if ( GameClient.inst != null ) {
			GameClient.inst.destroy();
			@:privateAccess Process._garbageCollector( Process.ROOTS );
		}
		new Client();
		new GameClient();
	}

	override function onResize() {
		super.onResize();

		// if ( Const.AUTO_SCALE_TARGET_WID > 0 )
		// 	Const.UI_SCALE = M.ceil(h() / Const.AUTO_SCALE_TARGET_WID);
		// else if ( Const.AUTO_SCALE_TARGET_HEI > 0 )
		// 	Const.UI_SCALE = M.floor(h() / Const.AUTO_SCALE_TARGET_HEI);

		root.setScale( Const.UI_SCALE );

		onResizeEvent.dispatch();
	}

	override function update() {
		// dn.heaps.slib.SpriteLib.TMOD = tmod;
		if ( ca.isKeyboardPressed( Key.F11 ) ) toggleFullscreen();
		// if ( ca.isKeyboardPressed(Key.M) ) Assets.toggleMusicPause();
		super.update();
	}
}
