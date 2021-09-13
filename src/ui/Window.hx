package ui;

import h2d.Layers;
import ui.WindowComp.WindowCompI;
import h2d.ScaleGrid;
import en.player.Player;
import h2d.Flow;
import h2d.Interactive;
import h2d.Object;
import ui.Dragable;

class Window extends dn.Process {
	public static var ALL : Array<Window> = [];

	var windowComp : WindowCompI;

	public var win : Object;
	/**backdround sprite**/
	var backgroundInter : Interactive;
	/**
		@param parent is usually supposed to be Player.inst.ui
	**/
	public function new( ?parent : h2d.Object ) {
		super(Game.inst);
		ALL.push(this);
		win = new h2d.Object(parent);

		dn.Process.resizeAll();
		Game.inst.delayer.addF(() -> {
			updateBackgroundInteractive();
		}, 1);
	}

	function updateBackgroundInteractive() {

		if ( win != null && windowComp != null ) {
			if ( backgroundInter != null ) backgroundInter.remove();

			backgroundInter = new Interactive(windowComp.window.innerWidth, windowComp.window.innerHeight);
			win.addChildAt(backgroundInter, 0);
			backgroundInter.cursor = Default;
			backgroundInter.onPush = function ( e ) {
				bringOnTopOfALL();
			};
		}
	}

	function recenter() {
		if ( win != null ) {
			var size = win.getSize();
			win.x = Std.int((wScaled - size.width) / 2);
			win.y = Std.int((hScaled - size.height) / 2);
		}
	}

	function clampInScreen() {
		if ( win != null && windowComp != null ) {
			win.x = hxd.Math.clamp(win.x, 0, Game.inst.w() / Const.SCALE - windowComp.window.innerWidth);
			win.y = hxd.Math.clamp(win.y, 0, Game.inst.h() / Const.SCALE - windowComp.window.innerHeight);
		}
	}

	public function bringOnTopOfALL() {
		try {
			Std.downcast(win.parent, Layers).add(win, Const.DP_UI);
		} catch( e ) {
			win.parent.addChild(win);
		}
		ALL.remove(this);
		ALL.unshift(this);
	}

	public function clearWindow() {
		win.removeChildren();
	}

	override function update() {
		super.update();
	}

	public inline function add( e : h2d.Flow ) {
		win.addChild(e);
		onResize();
	}

	override function onResize() {
		super.onResize();
		if ( win != null ) clampInScreen();
	}

	function onClose() {}

	override function onDispose() {
		super.onDispose();
		win.remove();
		ALL.remove(this);
	}

	public function toggleVisible() {
		win.visible = !win.visible;
		bringOnTopOfALL();
	}

	public function close() {
		if ( !destroyed ) {
			destroy();
			onClose();
		}
	}
}
