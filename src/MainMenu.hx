import ui.SaveManager;
import ui.SecondaryMenu;
import h2d.filter.Nothing;
import tools.Settings;
import ch2.ui.EventInteractive;
import dn.Process;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.Scene;
import h2d.Text;
import h2d.TextInput;
import h2d.Tile;
import h2d.filter.ColorMatrix;
import h3d.Matrix;
import h3d.mat.Texture;
import hxd.Event;
import hxd.System;
import ui.Button;

class MainMenu extends Process {
	var parentFlow : Object;
	var vertFlow : Flow;
	var socialFlow : Flow;
	var parents2d : Object;

	public function new(?parent : Object) {
		super(Main.inst);

		this.parents2d = parent;

		createRootInLayers(Main.inst.root, Const.DP_BG);
		parentFlow = new Object();

		root.add(parentFlow, Const.DP_BG);

		vertFlow = new Flow(parentFlow);
		socialFlow = new Flow(parentFlow);

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
		disco.onClickEvent.add((_) -> {
			System.openURL("https://discord.gg/8v2DFd6");
		});

		var twitter0 = new HSprite(Assets.ui, "twitter0");
		var twitter1 = new HSprite(Assets.ui, "twitter1");
		var twitter2 = new HSprite(Assets.ui, "twitter2");

		var twitter = new Button([twitter0.tile, twitter1.tile, twitter2.tile], socialFlow);
		twitter.scale(.5);
		twitter.onClickEvent.add((_) -> {
			System.openURL("https://twitter.com/GlassySundew");
		});

		socialFlow.addSpacing(-4);

		var vk0 = new HSprite(Assets.ui, "vk0");
		var vk1 = new HSprite(Assets.ui, "vk1");
		var vk2 = new HSprite(Assets.ui, "vk2");

		var vk = new Button([vk0.tile, vk1.tile, vk2.tile], socialFlow);
		vk.scale(.5);
		vk.onClickEvent.add((_) -> {
			System.openURL("https://vk.com/glassysundewartz");
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

		new TextButton("login", (_) -> {
			destroy();
			Main.inst.startGameClient();
		}, vertFlow);

		new TextButton("start demo (offline)", (_) -> {
			destroy();
			Main.inst.startGame();
			Game.inst.startLevel("ship_pascal");
		}, vertFlow);

		if ( saveFiles.length > 0 ) {
			var loadGame : Object = null;
			loadGame = new TextButton("load game", (_) -> {
				var loadMan = new SaveManager(Load, () -> {
					destroy();
				}, vertFlow);
				loadMan.x = loadGame.x + loadGame.getSize().xMax + 20;
				vertFlow.getProperties(loadMan).isAbsolute = true;
			}, vertFlow);
		}
		new TextButton("options", (_) -> {
			new OptionsMenu(root);
		}, vertFlow);

		new TextButton("exit", (_) -> {
			System.exit();
		}, vertFlow);

		// var but1 = new TextButton("Multiplayer", () -> {}, vertFlow);
		Boot.inst.engine.backgroundColor = 0x000000;
		onResize();
	}

	// override function update() {
	// 	super.update();
	// }
	override function onResize() {
		super.onResize();
		vertFlow.minHeight = socialFlow.minHeight = Std.int(Util.hScaled);
		vertFlow.minWidth = socialFlow.minWidth = Std.int(Util.wScaled);
	}

	override function onDispose() {
		super.onDispose();
		root.remove();
		root.removeChildren();
		this.destroy();
	}
}

class TextButton extends ui.Button {
	public function new(string : String, ?action : Event -> Void, ?colorDef : Int = 0xffffff, ?colorPressed : Int = 0x45798d, ?parent) {
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
		onClickEvent.add(action != null ? action : (_) -> {});
	}
}

class OptionsMenu extends SecondaryMenu {
	var vertFlow : Flow;
	var nicknameInput : ui.TextInput;

	public function new(?parent : Object) {
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
		nicknameInput.text = Settings.nickname != null ? Settings.nickname : "unnamed player";
		nicknameInput.onFocusLost = function(e : Event) {
			Settings.nickname = nicknameInput.text;
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

	override function sync(ctx : RenderContext) {
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
