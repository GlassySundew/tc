package;

import mapgen.MapGen;
import tools.Save;
import cherry.soup.EventSignal.EventSignal0;
import dn.M;
import dn.Process;
import en.player.Player;
import hxd.Key;
import tools.Settings;

@:publicFields
class Main extends Process {
	public static var inst : Main;

	public var console : ui.Console;
	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;
	public var onClose : EventSignal0;
	public var save : Save;

	public function new( s : h2d.Scene ) {
		super();
		inst = this;
		createRoot(s);

		// root.filter = new h2d.filter.ColorMatrix();

		#if( hl && pak )
		hxd.Res.initPak();
		#elseif( hl )
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		#end

		#if debug
		hxd.Res.data.watch(function () {
			delayer.cancelById("cdb");
			//
			delayer.addS("cdb", function () {
				Data.load(hxd.Res.data.entry.getBytes().toString());
				if ( Game.inst != null ) Game.inst.onCdbReload();
			}, 0.2);
		});
		#end
		Boot.inst.renderer = new CustomRenderer();
		Boot.inst.s3d.renderer = Boot.inst.renderer;
		Boot.inst.renderer.depthColorMap = hxd.Res.gradients.test.toTexture();
		Boot.inst.renderer.enableFXAA = false;
		Boot.inst.renderer.enableSao = false;

		Assets.init();
		Cursors.init();
		Lang.init("en");

		uiMap = MapCache.inst.get("ui.tmx");
		uiConf = uiMap.mapLayersByName();
		for ( i in uiConf ) {
			var window = i.getObjectByName("window");
			if ( window != null ) i.localBy(window);
		}

		Data.load(hxd.Res.data.entry.getText());

		console = new ui.Console(Assets.fontPixel, s);
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");

		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_NEG, Key.UP, Key.W);
		controller.bind(AXIS_LEFT_Y_POS, Key.DOWN, Key.S);

		controller.bind(A, Key.E);
		controller.bind(Y, Key.Q);
		// controller.bind(B, Key.ESCAPE, Key.BACKSPACE); // ??
		controller.bind(LT, Key.TAB); // Inventory
		controller.bind(DPAD_UP, Key.C);
		controller.bind(SELECT, Key.ESCAPE);

		onClose = new EventSignal0();

		Settings.loadSettings();

		onClose.add(() -> {
			if ( Player.inst != null ) {
				Player.inst.saveSettings();
			}
			Settings.saveSettings();
		});

		if ( Settings.params.fullscreen ) toggleFullscreen();

		@:privateAccess engine.window.onClose = function () {
			onClose.dispatch();
			return true;
		}
		save = new Save();

		delayer.addF(start, 1);
	}

	function start() {
		// Music
		#if !debug
		// Assets.playMusic();
		#end
		#if debug
		new MainMenu(Boot.inst.s2d);

		// var autoMapper = new mapgen.AutoMap("tiled/levels/rules.txt");
		// var mapGen = new MapGen(resolveMap('procgen/asteroids.tmx'), autoMapper);
		// var applicableMap = autoMapper.applyRulesToMap(resolveMap('asteroid.tmx'));

		// startGame();

		// Game.inst.startLevel("bridge.tmx");
		// Game.inst.startLevelFromParsedTmx(applicableMap, "test.tmx", {});
		#else
		new MainMenu(Boot.inst.s2d);
		#end
	}

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		s.displayMode = s.displayMode == Fullscreen ? Windowed : Fullscreen;
		Settings.params.fullscreen = s.displayMode == Fullscreen;
		#end
	}
	/** single-player **/
	public function startGame( ?seed : String ) {
		if ( Game.inst != null ) {
			Game.inst.destroy();
			@:privateAccess Process._garbageCollector(Process.ROOTS);
			new Game(seed);
		} else
			new Game(seed);
	}

	public function startGameClient() {
		if ( GameClient.inst != null ) {
			GameClient.inst.destroy();
			@:privateAccess Process._garbageCollector(Process.ROOTS);
			new GameClient();
		} else
			new GameClient();
	}

	override function onResize() {
		super.onResize();

		if ( Const.AUTO_SCALE_TARGET_WID > 0 ) Const.UI_SCALE = M.ceil(h() / Const.AUTO_SCALE_TARGET_WID); else if ( Const.AUTO_SCALE_TARGET_HEI > 0 )
			Const.UI_SCALE = M.floor(h() / Const.AUTO_SCALE_TARGET_HEI);
		root.setScale(Const.UI_SCALE);
	}

	override function update() {
		// dn.heaps.slib.SpriteLib.TMOD = tmod;
		if ( ca.isKeyboardPressed(Key.F11) ) toggleFullscreen();
		// if ( ca.isKeyboardPressed(Key.M) ) Assets.toggleMusicPause();
		// сделано наспех, итерирует по массиву ALL, скрывает первый видимый инстанс и выходит из цикла
		super.update();
	}
}
