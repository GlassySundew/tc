import dn.heaps.assets.Atlas;
import haxe.macro.ExprTools;
import haxe.macro.Expr.ExprDef;
import dn.heaps.slib.*;
import haxe.macro.Expr;
import haxe.macro.Context;

class Assets {
	// public static var SFX = dn.heaps.Sfx.importDirectory("sfx");
	public static var fontPixel : h2d.Font;

	// public static var fontTiny:h2d.Font;
	// public static var fontSmall:h2d.Font;
	// public static var fontMedium:h2d.Font;
	// public static var fontLarge:h2d.Font;
	public static var player : SpriteLib;
	public static var items : SpriteLib;
	public static var structures : SpriteLib;
	public static var ui : SpriteLib;
	public static var env : SpriteLib;

	static var music : dn.heaps.Sfx;

	public static function init() {

		dn.heaps.Sfx.muteGroup(0); // HACK
		dn.heaps.Sfx.setGroupVolume(0, 0.6);

		// #if js
		// music = new dn.heaps.Sfx(hxd.Res.music.leatherneck_js);
		// #else
		// music = new dn.heaps.Sfx(hxd.Res.music.leatherneck_hl);
		// #end
		// music.groupId = 1;

		fontPixel = hxd.Res.fonts.Haversham_new.toFont(); //toSdfFont(16, MultiChannel, 1, 1 / 16);

		// fontPixel.resizeTo(fontPixel.size >>1);
		// fontPixel
		// fontPixel.resizeTo(8);

		// fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		// fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		// fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		// fontLarge = hxd.Res.fonts.barlow_cxntondensed_medium_regular_32.toFont();

		player = Atlas.load(Const.ATLAS_PATH + "player.atlas");
		items = Atlas.load(Const.ATLAS_PATH + "items.atlas");
		structures = Atlas.load(Const.ATLAS_PATH + "structures.atlas");
		ui = Atlas.load(Const.ATLAS_PATH + "ui.atlas");
		env = Atlas.load(Const.ATLAS_PATH + "env.atlas");

		var action = ["idle_", "walk_"];
		var direc = ["left", "up", "down", "right", "down_left", "down_right", "up_left", "up_right"];
		// playerHero.defineAnim('idle_down_right', "0(1/0.25)");
		for ( i in 0...(direc.length - 1) ) player.generateAnim(action[0] + direc[i], "0(1)");
		for ( i in 0...(direc.length - 1) ) player.generateAnim(action[1] + direc[i], "0-3(1)");

		structures.defineAnim("hydroponics", "0-1");
		ui.defineAnim("keyboard_icon", "0-1");
	}

	public static function playMusic() {
		// trace("Playing music");
		// music.play(true);
	}

	public static function toggleMusicPause() {
		// music.togglePlay(true);
	}
}
