import core.VO;
import game.server.GameServer;
import game.test.VoxelSceneTest;
import cherry.soup.EventSignal.EventSignal0;
import cherry.soup.EventSignal;
import dn.Process;
import dn.heaps.input.Controller;
import dn.heaps.input.ControllerAccess;
import en.player.Player;
import game.client.ControllerAction;
import game.client.GameClient;
import h2d.Text;
import hxd.Key;
import net.Client;
import net.ClientController;
import pass.CustomRenderer;
import ui.MainMenu;
import util.Assets;
import util.Const;
import util.Cursors;
import util.Lang;
import util.MapCache;
import util.Repeater;
import util.Util;
import util.tools.Save;
import util.tools.Settings;

using util.Extensions.TmxLayerExtender;
using util.Extensions.TmxMapExtender;

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

	public var cliCon : VO<ClientController> = new VO( null );

	var fps : Text;

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
			Data.load( hxd.Res.data.entry.getBytes().toString() );
			// if ( GameServer.inst != null ) GameServer.inst.onCdbReload();
		} );
		#end

		Boot.inst.renderer = new CustomRenderer();
		Boot.inst.s3d.renderer = Boot.inst.renderer;
		// Boot.inst.renderer.depthColorMap = hxd.Res.gradients.test.toTexture();
		Boot.inst.renderer.enableFXAA = false;
		Boot.inst.renderer.enableSao = false;

		Assets.init();
		Cursors.init();
		Lang.init( "en" );

		Util.uiMap = MapCache.inst.get( "ui" );
		Util.uiConf = Util.uiMap.mapLayersByName();
		for ( i in Util.uiConf ) {
			var window = i.getObjectByName( "window" );
			if ( window != null ) i.localBy( window );
		}

		Data.load( hxd.Res.data.entry.getText() );

		console = new ui.Console( Assets.fontPixel, s );

		controller = Controller.createFromAbstractEnum( ControllerAction );
		ca = controller.createAccess();

		controller.bindKeyboard( MoveUp, [Key.UP, Key.W] );
		controller.bindKeyboard( MoveLeft, [Key.LEFT, Key.A] );
		controller.bindKeyboard( MoveDown, [Key.DOWN, Key.S] );
		controller.bindKeyboard( MoveRight, [Key.RIGHT, Key.D] );

		controller.bindPadLStick4( MoveLeft, MoveRight, MoveUp, MoveDown );

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

		start();
		new Client();

		fpsCounter();

		#if debug
		cliCon.onAppear(
			( cc ) -> new game.client.debug.ImGuiGameClientDebug( GameClient.inst )
		);
		#end
	}

	function fpsCounter() {
		fps = new Text( Assets.fontPixel, Boot.inst.s2d );
	}

	function start() {
		// VoxelSceneTest.start();
		MainMenu.spawn( Boot.inst.s2d );
	}

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		s.displayMode = s.displayMode == Fullscreen ? Windowed : Fullscreen;
		Settings.params.fullscreen = s.displayMode == Fullscreen;
		#end
	}

	/**
		start local server
	**/
	public function startGame( ?spawnServer = false ) {
		if ( GameClient.inst != null ) {
			GameClient.inst.destroy();
			@:privateAccess Process._garbageCollector( Process.ROOTS );
		}
		if ( spawnServer ) Boot.inst.createServer();
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
		Repeater.inst.update( tmod );

		if ( fps != null ) fps.text = '${Boot.inst.engine.fps}\ndraw calls: ${Boot.inst.engine.drawCalls}';
		super.update();
	}
}
