package ui;

import h2d.Tile;
import MainMenu.OptionsMenu;
import MainMenu.TextButton;
import dn.Process;
import en.player.Player;
import h2d.Flow;
import h2d.Graphics;
import h2d.Object;
import h2d.Text;
import h2d.filter.ColorMatrix;
import h3d.Matrix;

class PauseMenu extends Process {
	public static var inst : PauseMenu;
	var pauseContainer : Object;
	var backgroundGraphics : Graphics;
	var vertFlow : Flow;

	public function new() {
		super();
		if ( inst != null ) inst.destroy();
		inst = this;

		pauseContainer = new Object();

		Main.inst.root.add(pauseContainer, Const.DP_UI);

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
			vertFlow.fillHeight = true;
			vertFlow.fillWidth = true;

			vertFlow.backgroundTile = Tile.fromColor(0x000000, 1, 1, 0.5);

			var mm = new Text(Assets.fontPixel, vertFlow);
			mm.smooth = true;
			mm.scale(1.5);
			mm.text = "Menu";

			vertFlow.addSpacing(20);

			new TextButton("continue", (e) -> {
				exit();
			}, vertFlow);

			var saveGame : Object = null;
			saveGame = new TextButton("save game", (e) -> {
				// Main.inst.save.saveGame();
				var saveMan = new SaveManager(Save, pauseContainer);
				saveMan.x = saveGame.x + saveGame.getSize().xMax + 20;
				// saveMan.y = saveGame.y;
			}, vertFlow);

			var loadGame : Object = null;
			loadGame = new TextButton("load game", (e) -> {
				// exit();
				// Main.inst.save.loadGame();
				var loadMan = new SaveManager(Load, pauseContainer);
				loadMan.x = loadGame.x + loadGame.getSize().xMax + 20;
				// loadMan.y = loadGame.y;

				// "save/" + (Settings.saveFiles[0] == null ? "autosave" : Settings.saveFiles[0])
			}, vertFlow);

			new TextButton("options", (e) -> {
				var opts = new OptionsMenu(pauseContainer);
			}, vertFlow);

			new TextButton("exit to main menu", (e) -> {
				Game.inst.destroy();
				new MainMenu(Boot.inst.s2d);
				exit();
			}, vertFlow);

			onResize();
		});
		backgroundGraphics.scaleY = hScaled;
	}

	function exit() {
		destroy();
	}

	override function postUpdate() {
		super.postUpdate();

		if ( Player.inst != null && Player.inst.ca.selectPressed() && !Game.inst.pauseCycle ) {
			exit();
		}
		if ( Game.inst != null ) Game.inst.pauseCycle = false;
	}

	override function onDispose() {
		super.onDispose();
		pauseContainer.remove();
		if ( Game.inst != null ) {
			Game.inst.pauseCycle = true;
			Game.inst.resume();
		}
			
	}

	override function onResize() {
		super.onResize();
		if ( vertFlow != null ) {
			vertFlow.minWidth = vertFlow.maxWidth = wScaled;
			vertFlow.minHeight = vertFlow.maxHeight = hScaled;
			vertFlow.paddingTop = -Std.int(hScaled / 4);
		}

		backgroundGraphics.scaleX = wScaled / 3;
		backgroundGraphics.scaleY = hScaled;
	}
}
