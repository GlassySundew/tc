package;

// import game.comps.GameUI;
import hxd.Key;
import dn.M;
import dn.Process;
import hxd.Key;
import hxd.Res;
import game.data.ConfigJson;

@:publicFields
class Main extends Process {
	public static var inst:Main;
	public static var config:ConfigJson;

	public var controller:dn.heaps.Controller;
	public var ca:dn.heaps.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();

		inst = this;
		createRoot(s);

		root.filter = new h2d.filter.ColorMatrix();

		// #if debug
		// hxd.Res.initLocal();
		// #else
		// hxd.Res.initEmbed();
		// #end

		#if (js || embed_res)
		hxd.Res.initEmbed();
		#else
		hxd.Res.initLocal();
		#end

		#if debug
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.data.watch(function() {
			delayer.cancelById("cdb");

			delayer.addS("cdb", function() {
				Data.load(hxd.Res.data.entry.getBytes().toString());
				if (Game.inst != null)
					Game.inst.onCdbReload();
			}, 0.2);
		});
		#end

		Lang.init("en");
		Assets.init();
		// Data.load(hxd.Res.data.entry.getText());

		new ui.Console(Assets.fontPixel, s);

		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");

		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_NEG, Key.UP, Key.W);
		controller.bind(AXIS_LEFT_Y_POS, Key.DOWN, Key.S);
		controller.bind(A, Key.SPACE, Key.F, Key.E);
		controller.bind(B, Key.ESCAPE, Key.BACKSPACE);
		controller.bind(SELECT, Key.R);
		controller.bind(LT, Key.TAB);

		new dn.heaps.GameFocusHelper(Boot.inst.s2d, Assets.fontPixel);
		delayer.addF(start, 1);
	}

	function start() {
		// Music
		#if !debug
		Assets.playMusic();
		#end
		#if debug
		startGame();
		#else
		// new Title();
		#end
	}

	var full = false;

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		full = !full;
		s.displayMode = full ? Fullscreen : Windowed;
		#end
	}

	public function startGame() {
		if (Game.inst != null) {
			Game.inst.destroy();
			delayer.addS(function() {
				new Game();
			}, 0.1);
		} else
			new Game();
	}

	override function onResize() {
		super.onResize();

		if (Const.AUTO_SCALE_TARGET_WID > 0)
			Const.SCALE = M.ceil(h() / Const.AUTO_SCALE_TARGET_WID);
		else if (Const.AUTO_SCALE_TARGET_HEI > 0)
			Const.SCALE = M.floor(h() / Const.AUTO_SCALE_TARGET_HEI);
		root.setScale(Const.SCALE);
	}

	override function update() {
		dn.heaps.slib.SpriteLib.TMOD = tmod;

		if (ca.isKeyboardPressed(Key.F11))
			toggleFullscreen();

		if (ca.isKeyboardPressed(Key.M))
			Assets.toggleMusicPause();

		super.update();
	}
}
