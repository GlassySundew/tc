package ui;

import dn.Tweenie.TType;
import util.tools.Settings;
import util.Util;
import util.Const;
import dn.heaps.slib.HSprite;
import ui.core.TextButton;
import ui.core.Button;
import ui.core.ShadowedText;
import dn.Process;
import h2d.Bitmap;
import h2d.Flow;
import h2d.Object;
import h2d.Tile;
import hxd.System;
import ui.dialog.ConnectMenu;
import ui.dialog.NewSaveDialog;
import ui.dialog.OptionsMenu;
import ui.dialog.SaveManager;
import util.Assets;

class MainMenu extends Process {

	static var inst : MainMenu;

	var parentFlow : Flow;
	var vertFlow : Flow;
	var socialFlow : Flow;
	var planetFlow : Object;
	var blackOverlay : Bitmap;

	var isHostDebug : ShadowedText;

	public static function spawn( ?parent ) {
		if ( inst != null ) {
			inst.root.visible = true;
			return inst;
		} else {
			return new MainMenu( parent );
		}
	}

	public static function hide() {
		if ( inst != null )
			inst.root.visible = false;
	}

	function new( ?parent : Object ) {
		super( Main.inst );

		if ( inst != null ) inst.destroy();
		inst = this;

		createRoot( Main.inst.root );
		parentFlow = new Flow( root );

		vertFlow = new Flow( parentFlow );
		socialFlow = new Flow( parentFlow );
		planetFlow = new Object( parentFlow );

		parentFlow.getProperties( vertFlow ).isAbsolute = true;
		parentFlow.getProperties( socialFlow ).isAbsolute = true;
		parentFlow.getProperties( planetFlow ).isAbsolute = true;

		/*
			var riversBmp = new Bitmap(Tile.fromTexture(new Texture(100, 100)).center(), planetFlow);

			var riversShader = new shader.planets.rivers.Rivers();
			riversShader.pixels = 100;
			riversShader.river_cutoff = 0.368;
			riversShader.col1 = new Vector(0.388235, 0.670588, 0.247059, 1);
			riversShader.col2 = new Vector(0.231373, 0.490196, 0.309804, 1);
			riversShader.col3 = new Vector(0.184314, 0.341176, 0.32549, 1);
			riversShader.col4 = new Vector(0.156863, 0.207843, 0.25098, 1);
			riversShader.river_col = new Vector(0.309804, 0.643137, 0.721569, 1);
			riversShader.river_col_dark = new Vector(0.25098, 0.286275, 0.45098, 1);
			riversShader.dither_size = 2;
			riversShader.seed = Random.float(1, 10);
			riversShader.size = 3;
			riversShader.OCTAVES = 5;

			riversBmp.addShader(riversShader);

			var cloudsBmp = new Bitmap(Tile.fromTexture(new Texture(102, 102)).center(), planetFlow);

			var cloudsShader = new shader.planets.landMasses.Clouds();
			cloudsShader.pixels = 102;
			cloudsShader.cloud_cover = 0.47;
			cloudsShader.stretch = 2;
			cloudsShader.cloud_curve = 1.3;
			cloudsShader.light_border_1 = 0.52;
			cloudsShader.light_border_2 = 0.62;
			cloudsShader.base_color = new Vector(0.960784, 1, 0.909804, 1);
			cloudsShader.outline_color = new Vector(0.87451, 0.878431, 0.909804, 1);
			cloudsShader.shadow_base_color = new Vector(0.407843, 0.435294, 0.6, 1);
			cloudsShader.shadow_outline_color = new Vector(0.25098, 0.286275, 0.45098, 1);
			cloudsShader.size = 7.315;
			cloudsShader.OCTAVES = 2;
			cloudsShader.seed = Random.float(1, 10);

			cloudsBmp.addShader(cloudsShader);

			planetFlow.scale(1.9);

			cloudsShader.time_speed = 0.05;
			riversShader.time_speed = 0.03;
		 */

		socialFlow.verticalAlign = Bottom;
		socialFlow.horizontalAlign = Right;
		socialFlow.paddingRight = 7;
		socialFlow.paddingBottom = 7;
		socialFlow.horizontalSpacing = 9;

		var disco0 = new HSprite( Assets.ui, "discord0" );
		var disco1 = new HSprite( Assets.ui, "discord1" );
		var disco2 = new HSprite( Assets.ui, "discord2" );

		var disco = new Button( [disco0.tile, disco1.tile, disco2.tile], socialFlow );
		disco.scale( .5 );
		disco.onClickEvent.add( ( _ ) -> {
			System.openURL( "https://discord.gg/8v2DFd6" );
		} );

		var twitter0 = new HSprite( Assets.ui, "twitter0" );
		var twitter1 = new HSprite( Assets.ui, "twitter1" );
		var twitter2 = new HSprite( Assets.ui, "twitter2" );

		var twitter = new Button( [twitter0.tile, twitter1.tile, twitter2.tile], socialFlow );
		twitter.scale( .5 );
		twitter.onClickEvent.add( ( _ ) -> {
			System.openURL( "https://twitter.com/GlassySundew" );
		} );

		socialFlow.addSpacing( -4 );

		var vk0 = new HSprite( Assets.ui, "vk0" );
		var vk1 = new HSprite( Assets.ui, "vk1" );
		var vk2 = new HSprite( Assets.ui, "vk2" );

		var vk = new Button( [vk0.tile, vk1.tile, vk2.tile], socialFlow );
		vk.scale( .5 );
		vk.onClickEvent.add( ( _ ) -> System.openURL( "https://vk.com/totalcondemn" ) );
		socialFlow.getProperties( vk ).offsetY = -1;

		vertFlow.paddingLeft = 10;
		vertFlow.verticalAlign = Middle;
		vertFlow.layout = Vertical;
		vertFlow.verticalSpacing = 1;

		var mm = new ShadowedText( Assets.fontPixel, vertFlow );
		mm.scale( 1.5 );
		mm.text = "Total condemn";

		vertFlow.addSpacing( 10 );

		// new TextButton("login", ( _ ) -> {
		// 	destroy();
		// 	Main.inst.startClient();
		// }, vertFlow);

		var newGame : TextButton = null;
		newGame = new TextButton( "new game", ( _ ) -> {
			SaveManager.newSave( "new_game", "100000" );
			destroy();
		}, vertFlow );

		if ( Settings.params.saveFiles.length > 0 ) {
			var loadObj : Object = null;
			loadObj = new TextButton( "load game", ( _ ) -> {
				var loadMan = new SaveManager( Load, () -> destroy() );
				root.add( loadMan.h2dObject, Const.DP_UI );

				// loadMan.h2dObject.x = loadObj.x + loadObj.getSize().xMax + 20;
			}, vertFlow );
		}

		new TextButton( "connect", ( _ ) -> {
			new ConnectMenu(() -> destroy(), parentFlow );
		}, vertFlow );

		new TextButton( "options", ( _ ) -> {
			root.add( new OptionsMenu().h2dObject, Const.DP_UI );
		}, vertFlow );

		new TextButton( "exit", ( _ ) -> {
			System.exit();
		}, vertFlow );

		blackOverlay = new Bitmap( Tile.fromColor( 0x000000, Util.wScaled, Util.hScaled ) );

		parentFlow.addChildAt( blackOverlay, 1000 );
		parentFlow.getProperties( blackOverlay ).isAbsolute = true;

		Main.inst.tw.createS( blackOverlay.alpha, 1 > 0, TType.TBackOut, 2 ).end(() -> {
			blackOverlay.remove();
			blackOverlay = null;
		} );

		Boot.inst.engine.backgroundColor = 0x0c0c0c;

		#if debug
		// delayer.addF(() -> {
		// 	var client = new DebugClient();
		// 	isHostDebug = new ShadowedText( parentFlow );
		// 	parentFlow.getProperties( isHostDebug ).isAbsolute = true;
		// 	client.onConnection.add(() -> {
		// 		client.requestServerStatus( ( msg : Message ) -> {
		// 			switch msg {
		// 				case ServerStatus( isHost ):
		// 					trace( "got respond" );

		// 					if ( isHost ) {
		// 						isHostDebug.color = dn.Color.intToVector( 0x4cbb17 );
		// 						isHostDebug.text = "Host online";
		// 					} else {
		// 						isHostDebug.color = dn.Color.intToVector( 0xff0038 );
		// 						isHostDebug.text = "Host offline";
		// 					}
		// 				default: "";
		// 			}
		// 		} );
		// 	}, true );
		// }, 10 );
		#end

		onResize();
	}

	override function onResize() {
		super.onResize();

		planetFlow.x = Std.int( Util.wScaled * 0.74 );
		planetFlow.y = Std.int( Util.hScaled * 0.35 );
		planetFlow.scaleX = planetFlow.scaleY = Math.floor( w() / 720 + 1 );
		vertFlow.minHeight = vertFlow.maxHeight = socialFlow.minHeight = socialFlow.maxHeight = parentFlow.minHeight = parentFlow.maxHeight = Std.int( Util.hScaled );
		vertFlow.minWidth = vertFlow.maxWidth = socialFlow.minWidth = socialFlow.maxWidth = parentFlow.minWidth = parentFlow.maxWidth = Std.int( Util.wScaled );
	}

	override function onDispose() {
		super.onDispose();
		parentFlow.remove();
		inst = null;
		if ( blackOverlay != null ) blackOverlay.remove();
	}

	override function update() {
		super.update();
	}
}
