import h2d.filter.Bloom;
import h3d.Matrix;
import h2d.filter.ColorMatrix;
import dn.Process;
import h2d.Bitmap;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.Text;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import hxd.Event;
import hxd.System;
import tools.Settings;
import ui.Button;
import ui.SaveManager;
import ui.SecondaryMenu;

class MainMenu extends Process {
	var parentFlow : Flow;
	var vertFlow : Flow;
	var socialFlow : Flow;
	var planetFlow : Object;
	var camera : Camera;
	var parents2d : Object;
	var blackOverlay : Bitmap;

	public function new( ?parent : Object ) {
		super(Main.inst);

		this.parents2d = parent;

		parentFlow = new Flow();

		Main.inst.root.add(parentFlow, Const.DP_BG);

		camera = new Camera(this);

		vertFlow = new Flow(parentFlow);
		socialFlow = new Flow(parentFlow);
		planetFlow = new Object(parentFlow);

		parentFlow.getProperties(vertFlow).isAbsolute = true;
		parentFlow.getProperties(socialFlow).isAbsolute = true;
		parentFlow.getProperties(planetFlow).isAbsolute = true;

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

		socialFlow.verticalAlign = Bottom;
		socialFlow.horizontalAlign = Right;
		socialFlow.paddingRight = 7;
		socialFlow.paddingBottom = 7;
		socialFlow.horizontalSpacing = 9;

		var disco0 = new HSprite(Assets.ui, "discord0");
		var disco1 = new HSprite(Assets.ui, "discord1");
		var disco2 = new HSprite(Assets.ui, "discord2");

		var disco = new Button([disco0.tile, disco1.tile, disco2.tile], socialFlow);
		disco.scale(.5);
		disco.onClickEvent.add(( _ ) -> {
			System.openURL("https://discord.gg/8v2DFd6");
		});

		var twitter0 = new HSprite(Assets.ui, "twitter0");
		var twitter1 = new HSprite(Assets.ui, "twitter1");
		var twitter2 = new HSprite(Assets.ui, "twitter2");

		var twitter = new Button([twitter0.tile, twitter1.tile, twitter2.tile], socialFlow);
		twitter.scale(.5);
		twitter.onClickEvent.add(( _ ) -> {
			System.openURL("https://twitter.com/GlassySundew");
		});

		socialFlow.addSpacing(-4);

		var vk0 = new HSprite(Assets.ui, "vk0");
		var vk1 = new HSprite(Assets.ui, "vk1");
		var vk2 = new HSprite(Assets.ui, "vk2");

		var vk = new Button([vk0.tile, vk1.tile, vk2.tile], socialFlow);
		vk.scale(.5);
		vk.onClickEvent.add(( _ ) -> {
			System.openURL("https://vk.com/totalcondemn");
		});

		vertFlow.paddingLeft = 10;
		vertFlow.verticalAlign = Middle;
		vertFlow.layout = Vertical;
		vertFlow.verticalSpacing = 1;

		var mm = new Text(Assets.fontPixel, vertFlow);
		mm.smooth = true;
		mm.scale(1.5);
		mm.text = "Total condemn";

		vertFlow.addSpacing(10);

		new TextButton("login", ( _ ) -> {
			destroy();
			Main.inst.startGameClient();
		}, vertFlow);

		var newGame : TextButton = null;
		newGame = new TextButton("new game", ( _ ) -> {
			var dialog : NewSaveDialog = null;
			dialog = new NewSaveDialog(( e ) -> {
				Main.inst.startGame();
				Game.inst.startLevel("ship_pascal.tmx");
				Main.inst.delayer.addF(() -> {
					tools.Save.inst.saveGame(dialog.textInput.text);
				}, 1);
				destroy();
			}, Save, Main.inst.root);
			Main.inst.root.add(dialog, Const.DP_UI + 2);
			dialog.x = parentFlow.x;
			dialog.y = newGame.y;

			// destroy();
			// Main.inst.startGame();
			// Game.inst.startLevel("ship_pascal");
		}, vertFlow);

		if ( params.saveFiles.length > 0 ) {
			var loadGame : Object = null;
			loadGame = new TextButton("load game", ( _ ) -> {
				var loadMan = new SaveManager(Load, () -> {
					destroy();
				}, parentFlow);
				loadMan.x = loadGame.x + loadGame.getSize().xMax + 20;
				parentFlow.getProperties(loadMan).isAbsolute = true;
			}, vertFlow);
		}
		new TextButton("options", ( _ ) -> {
			new OptionsMenu(parentFlow);
		}, vertFlow);

		new TextButton("exit", ( _ ) -> {
			System.exit();
		}, vertFlow);

		// var but1 = new TextButton("Multiplayer", () -> {}, vertFlow);
		blackOverlay = new Bitmap(Tile.fromColor(0x000000, wScaled, hScaled));

		parentFlow.addChildAt(blackOverlay, 1000);
		parentFlow.getProperties(blackOverlay).isAbsolute = true;

		Main.inst.tw.createS(blackOverlay.alpha, 1 > 0, TBackOut, 2).end(() -> {
			blackOverlay.remove();
			blackOverlay = null;
		});

		Boot.inst.engine.backgroundColor = 0x0c0c0c;
		onResize();
	}

	override function onResize() {
		super.onResize();

		planetFlow.x = Std.int(Util.wScaled * 0.74);
		planetFlow.y = Std.int(Util.hScaled * 0.35);
		planetFlow.scaleX = planetFlow.scaleY = Math.floor(w() / 720 + 1);
		vertFlow.minHeight = vertFlow.maxHeight = socialFlow.minHeight = socialFlow.maxHeight = parentFlow.minHeight = parentFlow.maxHeight = Std.int(Util.hScaled);
		vertFlow.minWidth = vertFlow.maxWidth = socialFlow.minWidth = socialFlow.maxWidth = parentFlow.minWidth = parentFlow.maxWidth = Std.int(Util.wScaled);
	}

	override function onDispose() {
		super.onDispose();
		parentFlow.remove();

		if ( blackOverlay != null ) blackOverlay.remove();
	}
}

class TextButton extends ui.Button {
	public function new( string : String, ?action : Event -> Void, ?colorDef : Int = 0xffffff, ?colorPressed : Int = 0x45798d, ?parent ) {
		var text = new Text(Assets.fontPixel);
		text.color = Color.intToVector(colorDef);
		text.smooth = true;
		text.text = "  " + string;

		var tex0 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.drawTo(tex0);

		var tex1 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.text = "> " + string;
		text.drawTo(tex1);

		text.color = Color.intToVector(colorPressed);

		var tex2 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.drawTo(tex2);
		super([h2d.Tile.fromTexture(tex0), h2d.Tile.fromTexture(tex1), h2d.Tile.fromTexture(tex2)], parent);
		onClickEvent.add(action != null ? action : ( _ ) -> {});
	}
}

class OptionsMenu extends SecondaryMenu {
	var vertFlow : Flow;
	var nicknameInput : ui.TextInput;

	public function new( ?parent : Object ) {
		super(parent);

		vertFlow = new Flow(this);

		vertFlow.paddingLeft = 110;
		vertFlow.verticalAlign = Middle;
		vertFlow.layout = Vertical;
		vertFlow.verticalSpacing = 10;

		var mm = new Text(Assets.fontPixel, vertFlow);
		mm.smooth = true;
		mm.scale(1.5);
		mm.text = "Options";

		var horFlow = new Flow(vertFlow);
		horFlow.layout = Horizontal;
		horFlow.verticalAlign = Top;

		var nickname = new Text(Assets.fontPixel, horFlow);
		nickname.text = "username: ";

		nicknameInput = new ui.TextInput(Assets.fontPixel, horFlow);
		nicknameInput.text = Settings.params.nickname;
		nicknameInput.onFocusLost = function ( e : Event ) {
			Settings.params.nickname = nicknameInput.text;
			Settings.saveSettings();
		}

		// nicknameInput.onKeyDown = function(e : Event) {
		// 	if ( e.keyCode == Key.ENTER ) {
		// 		Util.nickname = nicknameInput.text;
		// 		Util.saveSettings();
		// 		if ( onRemoveEvent != null ) onRemoveEvent();
		// 	}
		// }
	}

	override function sync( ctx : RenderContext ) {
		vertFlow.minHeight = Std.int(Util.hScaled);
		vertFlow.minWidth = Std.int(Util.wScaled);
		vertFlow.paddingTop = -Std.int(Util.hScaled / 4);
		super.sync(ctx);

		if ( Main.inst.ca.isPressed(SELECT) ) {
			remove();
		}
	}

	override function onRemove() {
		super.onRemove();
	}
}
