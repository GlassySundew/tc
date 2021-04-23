package;

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

		uiConf = resolveMap("ui.tmx").getLayersByName();
		for (i in uiConf) i.localBy(i.getObjectByName("window"));

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

		@:privateAccess engine.window.onClose = function() {
			onClose.dispatch();
			return true;
		}
		save = new Save();

		delayer.addF(start, 1);
	}

	function start() {
		// Music
		// #if !debug
		Assets.playMusic();
		new MainMenu(Boot.inst.s2d);
		// #end
		// #if debug
		// startGame();
		// Game.inst.startLevel("ship_pascal.tmx");
		// #end
	}

	public function toggleFullscreen() {
		#if hl
		var s = hxd.Window.getInstance();
		s.displayMode = s.displayMode == Fullscreen ? Windowed : Fullscreen;
		Settings.params.fullscreen = s.displayMode == Fullscreen;
		#end
	}

	public function startGame() {
		if ( Game.inst != null ) {
			Game.inst.destroy();
			delayer.addF(function() {
				new Game();
			}, 2);
		} else
			new Game();
	}

	public function startGameClient() {
		if ( GameClient.inst != null ) {
			GameClient.inst.destroy();
			delayer.addF(function() {
				new GameClient();
			}, 2);
		} else
			new GameClient();
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
		// сделано наспех, итерирует по массиву ALL, скрывает первый видимый инстанс и выходит из цикла
		super.update();
	}
}
