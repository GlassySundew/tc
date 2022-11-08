package ui;

import utils.Util;
import dn.Tweenie.TType;
import ui.core.TextButton;
import ui.core.ShadowedText;
import net.Client;
import game.client.GameClient;
import utils.Assets;
import dn.Process;
import h2d.Flow;
import h2d.Graphics;
import h2d.Object;
import ui.dialog.FocusMenu;
import ui.dialog.OptionsMenu;
import ui.dialog.SaveManager;

class PauseMenu extends FocusMenu {

	public static var inst : PauseMenu;

	var backgroundGraphics : Graphics;
	var pausableProcess : Process;

	public function new( pausableProcess : Process, ?parent : h2d.Object, ?parentProcess : Process ) {
		super( parent, parentProcess );
		pausableProcess.pause();
		this.pausableProcess = pausableProcess;

		centrizeContent( 0 );
		contentFlow.padding = 10;

		if ( inst != null ) inst.destroy();
		inst = this;

		backgroundGraphics = new Graphics( contentFlow );
		initContent();

		addOnSceneAddedCb( initFlow );
	}

	function initContent() {
		var mm = new ShadowedText( Assets.fontPixel, contentFlow );
		mm.scale( 1.5 );
		mm.text = "Menu";

		contentFlow.addSpacing( 20 );

		new TextButton( "continue", ( e ) -> {
			destroy();
		}, contentFlow );

		var saveGameClient : Object = null;
		saveGameClient = new TextButton( "save game", ( e ) -> {
			// Main.inst.save.saveGameClient();
			var saveMan = new SaveManager( Save, h2dObject );
			saveMan.h2dObject.x = saveGameClient.x + saveGameClient.getSize().xMax + 20;
			// saveMan.y = saveGameClient.y;
		}, contentFlow );

		var loadObj : Object = null;
		loadObj = new TextButton( "load game", ( e ) -> {
			// exit();
			// Main.inst.save.loadGameClient();
			var loadMan = new SaveManager( Load, h2dObject );
			loadMan.h2dObject.x = loadObj.x + loadObj.getSize().xMax + 20;
			// loadMan.y = loadGameClient.y;

			// "save/" + (Settings.saveFiles[0] == null ? "autosave" : Settings.saveFiles[0])
		}, contentFlow );

		new TextButton( "options", ( e ) -> {
			new OptionsMenu( h2dObject );
		}, contentFlow );

		new TextButton( "exit to main menu", ( e ) -> {
			Client.inst.sendMessage( Disconnect );
			GameClient.inst.destroy();

			// TODO make
			// Save.inst.disconnect();

			MainMenu.spawn( Boot.inst.s2d );
			destroy();
		}, contentFlow );

		contentFlow.visible = false;
	}

	function initFlow() {

		// выезжающая панель
		backgroundGraphics.beginFill( 0xffffff );
		backgroundGraphics.addVertex( 0, 1, 0, 0, 0, .75 );
		backgroundGraphics.addVertex( 0, 0, 0, 0, 0, .75 );
		backgroundGraphics.addVertex( 1, 0, 0, 0, 0, .20 );
		backgroundGraphics.addVertex( 1, 1, 0, 0, 0, .20 );
		backgroundGraphics.endFill();
		contentFlow.getProperties( backgroundGraphics ).isAbsolute = true;

		Main.inst.tw.createMs( backgroundGraphics.scaleX, contentFlow.outerWidth, TType.TEaseOut, 320 ).end(() -> {
			contentFlow.visible = true;
			onResize();
		} );
		backgroundGraphics.scaleY = Util.hScaled;
	}

	override function onDispose() {
		super.onDispose();

		pausableProcess.resume();
	}

	override function onResize() {
		super.onResize();

		// if ( vertFlow != null ) {
		// 	vertFlow.minWidth = vertFlow.maxWidth = wScaled;
		// 	vertFlow.minHeight = vertFlow.maxHeight = hScaled;
		// 	vertFlow.paddingTop = -Std.int(hScaled / 4);
		// }

		// backgroundGraphics.scaleX = wScaled / 3;
		// backgroundGraphics.scaleY = hScaled;
	}
}
