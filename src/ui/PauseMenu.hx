package ui;

import MainMenu.OptionsMenu;
import MainMenu.TextButton;
import dn.Process;
import en.player.Player;
import h2d.Flow;
import h2d.Graphics;
import h2d.Object;
import h2d.Tile;
import tools.Save;

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

		GameClient.inst.root.add(pauseContainer, Const.DP_UI_FRONT);

		var backgroundFlowForInteractive = new Flow(pauseContainer);
		backgroundFlowForInteractive.fillHeight = true;
		backgroundFlowForInteractive.fillWidth = true;
		backgroundFlowForInteractive.enableInteractive = true;

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

			var mm = new ShadowedText(Assets.fontPixel, vertFlow);
			mm.scale(1.5);
			mm.text = "Menu";

			vertFlow.addSpacing(20);

			new TextButton("continue", ( e ) -> {
				exit();
			}, vertFlow);

			var saveGameClient : Object = null;
			saveGameClient = new TextButton("save game", ( e ) -> {
				// Main.inst.save.saveGameClient();
				var saveMan = new SaveManager(Save, pauseContainer);
				saveMan.x = saveGameClient.x + saveGameClient.getSize().xMax + 20;
				// saveMan.y = saveGameClient.y;
			}, vertFlow);

			var loadObj : Object = null;
			loadObj = new TextButton("load game", ( e ) -> {
				// exit();
				// Main.inst.save.loadGameClient();
				var loadMan = new SaveManager(Load, pauseContainer);
				loadMan.x = loadObj.x + loadObj.getSize().xMax + 20;
				// loadMan.y = loadGameClient.y;

				// "save/" + (Settings.saveFiles[0] == null ? "autosave" : Settings.saveFiles[0])
			}, vertFlow);

			new TextButton("options", ( e ) -> {
				var opts = new OptionsMenu(pauseContainer);
			}, vertFlow);

			new TextButton("exit to main menu", ( e ) -> {
				GameClient.inst.destroy();

				// TODO make 
				// Save.inst.disconnect();

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

		if ( Player.inst != null && Player.inst.ca.selectPressed() && !GameClient.inst.pauseCycle ) {
			exit();
		}
		if ( GameClient.inst != null ) GameClient.inst.pauseCycle = false;
	}

	override function onDispose() {
		super.onDispose();
		pauseContainer.remove();
		if ( GameClient.inst != null ) {
			GameClient.inst.pauseCycle = true;
			GameClient.inst.resume();
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
