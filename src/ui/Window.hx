package ui;

import en.player.Player;
import h2d.Flow;
import h2d.Interactive;
import h2d.Object;
import ui.Dragable;

class Window extends dn.Process {
	public static var ALL : Array<Window> = [];

	public var dragable : Dragable;
	public var win : Object;
	/**backdround sprite**/
	var spr : HSprite;

	static var centrizerFlow : Flow;

	public function new(?parent : h2d.Object) {
		super(Main.inst);
		ALL.push(this);
		win = new h2d.Object(parent);
		if ( spr != null ) {
			win.addChild(spr);

			var backgroundInter = new Interactive(spr.tile.width, spr.tile.height, spr);
			backgroundInter.cursor = Default;
			backgroundInter.onPush = function(e) {
				bringOnTopOfALL();
			}
		}

		dn.Process.resizeAll();
	}
	/** Create close button based on config **/
	function createCloseBut(layerConf : String) {
		var closeConf = uiConf.get(layerConf).getObjectByName("close");

		var close_button_inventory0 = new HSprite(Assets.ui, "close_button_inventory0");
		var close_button_inventory1 = new HSprite(Assets.ui, "close_button_inventory1");
		var close_button_inventory2 = new HSprite(Assets.ui, "close_button_inventory2");

		var closeButton = new Button([
			close_button_inventory0.tile,
			close_button_inventory1.tile,
			close_button_inventory2.tile
		], spr);

		closeButton.x = closeConf.x;
		closeButton.y = closeConf.y;

		closeButton.onClickEvent.add((_) -> {
			toggleVisible();
		});
	}
	/**create dragable area based on config**/
	function createDragable(layerConf : String) {
		var dragableConf = uiConf.get(layerConf).getObjectByName("dragable");
		dragable = new Dragable(dragableConf.width, dragableConf.height, (deltaX : Float, deltaY : Float) -> {
			win.x += deltaX;
			win.y += deltaY;

			Player.inst.ui.add(win, Const.DP_UI);
			clampInScreen();
			bringOnTopOfALL();
		}, win);
		delayer.addF(() -> {
			dragable.onDrag.dispatch(0, 0);
		}, 1);
		dragable.x = dragableConf.x;
		dragable.y = dragableConf.y;
	}

	function recenter() {
		if ( spr != null ) {
			win.x = Std.int((wScaled - spr.tile.width) / 2);
			win.y = Std.int((hScaled - spr.tile.height) / 2);
		}
	}

	function clampInScreen() {
		win.x = hxd.Math.clamp(win.x, 0, Game.inst.w() / Const.SCALE - spr.tile.width);
		win.y = hxd.Math.clamp(win.y, 0, Game.inst.h() / Const.SCALE - spr.tile.height);
	}

	function bringOnTopOfALL() {
		win.parent.addChild(win);
		ALL.remove(this);
		ALL.unshift(this);
	}

	public function toggleVisible() {
		bringOnTopOfALL();
		win.visible = !win.visible;
		// recenter();
	}

	public function clearWindow() {
		win.removeChildren();
	}

	// TODO
	public static function centrizeTwoWins(win1 : Window, win2 : Window) {
		if ( centrizerFlow != null ) {
			centrizerFlow.onAfterReflow = () -> {};
			centrizerFlow.remove();
		}

		centrizerFlow = new Flow();

		centrizerFlow.paddingLeft = Std.int(win1.win.x);
		centrizerFlow.paddingTop = Std.int(win1.win.y);
		centrizerFlow.x -= (win1.win.getSize().xMax + win2.win.getSize().xMax) / 4;

		if ( centrizerFlow.paddingLeft + centrizerFlow.x < 0 ) centrizerFlow.paddingLeft += M.iabs(centrizerFlow.paddingLeft + Std.int(centrizerFlow.x));
		if ( centrizerFlow.paddingLeft + centrizerFlow.x + (win1.win.getSize().xMax + win2.win.getSize().xMax) > Util.wScaled ) {
			centrizerFlow.paddingLeft -= Std.int(centrizerFlow.paddingLeft + centrizerFlow.x + (win1.win.getSize().xMax + win2.win.getSize().xMax)
				- Util.wScaled);
		}

		centrizerFlow.addChild(win1.win);
		centrizerFlow.addChild(win2.win);

		centrizerFlow.verticalAlign = Middle;
		centrizerFlow.horizontalAlign = Middle;

		Player.inst.ui.add(centrizerFlow, Const.DP_UI);

		win1.clampInScreen();
		win2.clampInScreen();

		centrizerFlow.reflow();
		centrizerFlow.needReflow = false;

		centrizerFlow.onAfterReflow = function() {
			if ( win1.win.parent != centrizerFlow || !win1.win.visible ) {
				// Кто-то потянул за первое окно и его родитель стал Player.inst.ui вместо centrizerFlow
				win1.win.x -= win1.win.getSize().xMax / 2;
				win2.win.x += win1.win.getSize().xMax;
				// Player.inst.ui.add(win1.win, Const.DP_UI);
			} else if ( win2.win.parent != centrizerFlow || !win2.win.visible ) {
				// Кто-то потянул за win2
				win2.win.x -= win2.win.getSize().xMax / 2;
				// Player.inst.ui.add(win2.win, Const.DP_UI);
			}

			centrizerFlow.onAfterReflow = () -> {};
		}
	}

	override function update() {
		super.update();
	}

	public static function removeCentrizer() {
		centrizerFlow.remove();
	}

	public inline function add(e : h2d.Flow) {
		win.addChild(e);
		onResize();
	}

	override function onResize() {
		super.onResize();
		if ( spr != null ) clampInScreen();
	}

	function onClose() {}

	override function onDispose() {
		super.onDispose();
		win.remove();
		ALL.remove(this);
	}

	public function close() {
		if ( !destroyed ) {
			destroy();
			onClose();
		}
	}
}
