import dn.heaps.slib.assets.Atlas;
import haxe.macro.ExprTools;
import haxe.macro.Expr.ExprDef;
import dn.heaps.slib.*;
import haxe.macro.Expr;
import haxe.macro.Context;

class Assets {
	// public static var SFX = dn.heaps.Sfx.importDirectory("sfx");
	public static var fontPixel:h2d.Font;

	// public static var fontTiny:h2d.Font;
	// public static var fontSmall:h2d.Font;
	// public static var fontMedium:h2d.Font;
	// public static var fontLarge:h2d.Font;
	public static var tiles:SpriteLib;
	public static var items:SpriteLib;

	static var music:dn.heaps.Sfx;

	static var initDone = false;

	public static function init() {
		if (initDone)
			return;
		initDone = true;

		dn.heaps.Sfx.muteGroup(0); // HACK
		dn.heaps.Sfx.setGroupVolume(0, 0.6);

		// #if js
		// music = new dn.heaps.Sfx(hxd.Res.music.leatherneck_js);
		// #else
		// music = new dn.heaps.Sfx(hxd.Res.music.leatherneck_hl);
		// #end
		// music.groupId = 1;

		fontPixel = hxd.Res.fonts.Haversham_fnt.toFont();
		fontPixel.resizeTo(16);
		
		// fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		// fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		// fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		// fontLarge = hxd.Res.fonts.barlow_cxntondensed_medium_regular_32.toFont();

		tiles = Atlas.load("tiled/player_move.atlas");

		var action = ["idle_", "walk_"];
		var direc = ["left", "up", "down", "right", "down_left", "down_right", "up_left", "up_right"];
		// tilesHero.defineAnim('idle_down_right', "0(1/0.25)");
		for (i in 0...(direc.length - 1))
			tiles.generateAnim(action[0] + direc[i], "0(1)");
		for (i in 0...(direc.length - 1))
			tiles.generateAnim(action[1] + direc[i], "0-3(1)");

		items = Atlas.load("tiled/items.atlas");
	}

	public static function playMusic() {
		trace("Playing music");
		// music.play(true);
	}

	public static function toggleMusicPause() {
		// music.togglePlay(true);
	}
}
