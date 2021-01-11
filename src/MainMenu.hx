import haxe.io.Path;
import h2d.TextInput;
import cherry.soup.EventSignal.EventSignal0;
import ch2.ui.EventInteractive;
import h3d.Matrix;
import h2d.filter.ColorMatrix;
import h2d.filter.Bloom;
import h2d.filter.Blur;
import hxd.Event;
import hxd.res.Resource;
import hxd.System;
import ui.Button;
import tools.Util;
import dn.Process;
import h2d.Scene;
import h2d.RenderContext;
import h3d.mat.Texture;
import h2d.Tile;
import h2d.Flow;
import h2d.Text;
import h2d.Object;

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

		new TextButton("start demo", (_) -> {
			root.remove();
			root.removeChildren();
			this.destroy();
			Main.inst.startGame();
		}, vertFlow);

		new TextButton("options", (_) -> {
			var m = new Matrix();
			m.identity();
			m.colorGain(0x0, .7);
			var cm = new ColorMatrix(m);
			parentFlow.filter = cm;
			new OptionsMenu(root, () -> {
				parentFlow.filter = null;
			});
		}, vertFlow);

		new TextButton("exit", (_) -> {
			System.exit();
		}, vertFlow);

		// var but1 = new TextButton("Multiplayer", () -> {}, vertFlow);
	}

	// override function update() {
	// 	super.update();
	// }
	override function onResize() {
		super.onResize();
		vertFlow.minHeight = socialFlow.minHeight = Std.int(Util.getS2dScaledHei());
		vertFlow.minWidth = socialFlow.minWidth = Std.int(Util.getS2dScaledWid());
		// vertFlow.paddingTop = -Std.int(Util.getS2dScaledHei() / 4);
	}

	// override function sync(ctx : RenderContext) {
	// 	super.sync(ctx);
	// }

	override function onDispose() {
		super.onDispose();
	}
}

class TextButton extends ui.Button {
	public function new(string : String, action : Event->Void, ?parent) {
		var text = new Text(Assets.fontPixel);
		text.smooth = true;
		text.text = "  " + string;

		var tex0 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.drawTo(tex0);

		var tex1 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.text = "> " + string;
		text.drawTo(tex1);

		text.color = Color.intToVector(0x6b8fc2);
		var tex2 = new Texture(Std.int(text.textWidth), Std.int(text.textHeight), [Target]);
		text.drawTo(tex2);
		super([h2d.Tile.fromTexture(tex0), h2d.Tile.fromTexture(tex1), h2d.Tile.fromTexture(tex2)], parent);
		onClickEvent.add(action);
	}
}

class OptionsMenu extends Object {
	var vertFlow : Flow;

	var onRemoveEvent : Void->Void;
	var nicknameInput : ui.TextInput;

	public function new(?parent, ?onRemove : Void->Void) {
		super(parent);
		this.onRemoveEvent = onRemove;
		var exitInteractive = new EventInteractive(Util.getS2dScaledWid(), Util.getS2dScaledHei(), this);

		exitInteractive.onClickEvent.add((_) -> {
			remove();
			if ( onRemove != null ) onRemove();
		});

		exitInteractive.cursor = Default;

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
		nickname.text = "Nickname: ";

		nicknameInput = new ui.TextInput(Assets.fontPixel, horFlow);
		nicknameInput.text = Util.nickname != null ? Util.nickname : "Unnamed player";
	}

	override function sync(ctx : RenderContext) {
		vertFlow.minHeight = Std.int(Util.getS2dScaledHei());
		vertFlow.minWidth = Std.int(Util.getS2dScaledWid());
		vertFlow.paddingTop = -Std.int(Util.getS2dScaledHei() / 4);
		super.sync(ctx);

		if ( Main.inst.ca.isPressed(SELECT) ) {
			Util.nickname = nicknameInput.text;
			Util.saveSettings();
			remove();
			if ( onRemoveEvent != null ) onRemoveEvent();
		}
	}
}
