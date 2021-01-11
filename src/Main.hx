package;

// import game.comps.GameUI;
import tools.Util;
import hxd.fmt.pak.FileSystem;
import h3d.mat.Texture;
import h2d.Bitmap;
import hxd.Cursor.CustomCursor;
import hxd.BitmapData;
import hxd.Pixels;
import hxd.Key;
import dn.M;
import dn.Process;
import hxd.Key;
import hxd.Res;

@:publicFields
class Main extends Process {
	public static var inst : Main;

	public var console : ui.Console;
	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function new(s : h2d.Scene) {
		super();
		inst = this;
		createRoot(s);

		// root.filter = new h2d.filter.ColorMatrix();

		#if( hl && pak )
		hxd.Res.initPak();
		#elseif( hl )
		hxd.Res.initLocal();
		#end

		hxd.res.Resource.LIVE_UPDATE = true;
		#if debug
		hxd.Res.data.watch(function() {
			delayer.cancelById("cdb");
			//
			delayer.addS("cdb", function() {
				Data.load(hxd.Res.data.entry.getBytes().toString());
				if ( Game.inst != null ) Game.inst.onCdbReload();
			}, 0.2);
		});
		#end

		Assets.init();
		Cursors.init();
		Lang.init("en");

		Data.load(hxd.Res.data.entry.getText());
		// Data.load(hxd.Res.data.entry.getText());
		
		console = new ui.Console(Assets.fontPixel, s);
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");

		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_NEG, Key.UP, Key.W);
		controller.bind(AXIS_LEFT_Y_POS, Key.DOWN, Key.S);
		controller.bind(A, Key.SPACE, Key.F, Key.E);
		controller.bind(B, Key.ESCAPE, Key.BACKSPACE);
		controller.bind(SELECT, Key.R);
		controller.bind(LT, Key.TAB); // Inventory
		controller.bind(DPAD_UP, Key.C);
		controller.bind(SELECT, Key.ESCAPE);

		// @:privateAccess new dn.heaps.GameFocusHelper(Boot.inst.s2d, Assets.fontPixel);

		// delayer.addF(start, 1);
		Util.loadSettings();
		start();
	}

	function start() {
		// Music
		#if !debug
		Assets.playMusic();
		new MainMenu(Boot.inst.s2d);
		#end
		#if debug
		startGame();
		#else
		// new Title();
		#end
	}

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		s.displayMode = s.displayMode == Fullscreen ? Windowed : Fullscreen;
		#end
	}

	public function startGame() {
		if ( Game.inst != null ) {
			Game.inst.destroy();
			// delayer.addS(function() {
			new Game();
			// }, 0.1);
		} else
			new Game();
	}

	override function onResize() {
		super.onResize();

		if ( Const.AUTO_SCALE_TARGET_WID > 0 ) Const.SCALE = M.ceil(h() / Const.AUTO_SCALE_TARGET_WID); else if ( Const.AUTO_SCALE_TARGET_HEI > 0 )
			Const.SCALE = M.floor(h() / Const.AUTO_SCALE_TARGET_HEI);
		root.setScale(Const.SCALE);

		// Boot.inst.s2d.scaleMode = Zoom(Const.SCALE);
	}

	override function update() {
		// dn.heaps.slib.SpriteLib.TMOD = tmod;
		if ( ca.isKeyboardPressed(Key.F11) ) toggleFullscreen();
		// if ( ca.isKeyboardPressed(Key.M) ) Assets.toggleMusicPause();

		super.update();
	}
}
