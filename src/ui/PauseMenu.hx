package ui;

import h2d.filter.Nothing;
import h2d.filter.ColorMatrix;
import h3d.Matrix;
import MainMenu.OptionsMenu;
import MainMenu.TextButton;
import h2d.Text;
import h2d.Flow;
import en.player.Player;
import dn.Process;
import h2d.Graphics;
import h2d.Tile;
import h2d.Object;

class PauseMenu extends Process {
	var pauseContainer : Object;
	var backgroundGraphics : Graphics;
	var vertFlow : Flow;

	public function new() {
		super();
		pauseContainer = new Object(Player.inst.ui);
		backgroundGraphics = new Graphics(pauseContainer);

		backgroundGraphics.beginFill(0xffffff);

		backgroundGraphics.addVertex(0, 1, 0, 0, 0, .75);
		backgroundGraphics.addVertex(0, 0, 0, 0, 0, .75);
		backgroundGraphics.addVertex(1, 0, 0, 0, 0, .20);
		backgroundGraphics.addVertex(1, 1, 0, 0, 0, .20);

		backgroundGraphics.endFill();

		Main.inst.tw.createMs(backgroundGraphics.scaleX, 0 | wScaled / 3, TEaseOut, 320).end(() -> {
			vertFlow = new Flow(pauseContainer);
			vertFlow.paddingLeft = 10;
			vertFlow.verticalAlign = Middle;
			vertFlow.layout = Vertical;
			vertFlow.verticalSpacing = 1;

			var mm = new Text(Assets.fontPixel, vertFlow);
			mm.smooth = true;
			mm.scale(1.5);
			mm.text = "Menu";

			vertFlow.addSpacing(20);

			new TextButton("continue", (e) -> {
				exit();
			}, vertFlow);

			new TextButton("save game", (e) -> {
				Game.inst.save.saveGame();
			}, vertFlow);

			new TextButton("options", (e) -> {
				var m = new Matrix();
				m.identity();
				m.colorGain(0x0, .7);
				var cm = new ColorMatrix(m);
				vertFlow.filter = cm;
				var opts = new OptionsMenu(pauseContainer, () -> {
					vertFlow.filter = null;
				});
			}, vertFlow);

			new TextButton("exit to main menu", (e) -> {
				exit();
				Game.inst.destroy();
				new MainMenu(Boot.inst.s2d);
			}, vertFlow);

			onResize();
		});
		backgroundGraphics.scaleY = hScaled;
	}

	function exit() {
		Game.inst.resume();
		Game.inst.pauseCycle = true;
		destroy();
	}

	override function postUpdate() {
		super.postUpdate();

		if ( Player.inst.ca.selectPressed() && !Game.inst.pauseCycle ) {
			exit();
		}
		Game.inst.pauseCycle = false;
	}

	override function onDispose() {
		super.onDispose();
		pauseContainer.remove();
	}

	override function onResize() {
		super.onResize();
		if ( vertFlow != null ) {
			vertFlow.minWidth = wScaled;
			vertFlow.minHeight = hScaled;
			vertFlow.paddingTop = -Std.int(hScaled / 4);
		}

		backgroundGraphics.scaleX = wScaled / 3;
		backgroundGraphics.scaleY = hScaled;
	}
}
