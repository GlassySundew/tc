package;

// import game.comps.GameUI;
import format.tmx.*;
import engine.Music;
import engine.Locale;
import hxd.snd.ChannelGroup;
import engine.utils.DebugDIsplay;
import engine.utils.MacroUtil;
import hxd.Timer;
import haxe.Json;
import engine.HXP;
import engine.S3DComponent;
import h3d.scene.Object;
import h3d.mat.Texture;
import hxd.fmt.hmd.Library;
import hxd.Res;
import h3d.prim.Cube;
import h3d.scene.Mesh;
import gasm.core.Entity;
import gasm.heaps.HeapsContext;
import engine.S3DRenderer;
import engine.HPEngine;
import game.data.ConfigJson;

@:publicFields
class Main extends HPEngine {
	public static var inst:Main;
	public static var config:ConfigJson;

	public static var sfxChannel(get, never):ChannelGroup;

	private static function get_sfxChannel():ChannelGroup {
		return HXP.sfxChannel;
	}

	public static var flags:Array<String> = new Array();
	public static var atbSpeed:Float = 1;

	override function init() {
		super.init();

		//	GameUI.init_base();
		scene = new game.TestScene();
		//	GameUI.init_base();
		//	scene = new game.MenuScene();
		
		#if js
		js.Syntax.code("window.addEventListener(\"wheel\", (e) => { e.preventDefault(); return false; })");
		#end
		
	}

	override function onResize() {}

	static function main() {
		#if (js || embed_res)
		hxd.Res.initEmbed();
		#else
		hxd.Res.initLocal();
		#end
		Data.load(hxd.Res.data.entry.getBytes().toString());
		inst = new Main();
	}

	public function new() {
		super();
	}
}
