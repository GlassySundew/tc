package ui;

import en.player.Player;
import haxe.CallStack;
import ui.WindowComp.WindowCompI;
import h2d.Object;
import h2d.Tile;
import haxe.Constraints.Constructible;
import h2d.ScaleGrid;
import h2d.Flow;
import format.tmx.*;

@:generic
class NinesliceWindow extends Window {
	public function new( ?background : String = "window", domkitConstrucor : ( h2d.Tile, Int, Int, Int, Int, h2d.Object ) -> WindowCompI,
			parent : h2d.Object ) {
		super(parent);

		var backgroundConf = uiConf.get(background).getObjectByName("window");
		var nineSlice = uiConf.get(background).getObjectByName("9slice");

		switch backgroundConf.objectType {
			case OTTile(gid):
				var picName = Tools.getTileByGid(uiMap, gid).image.source;
				if ( eregFileName.match(picName) ) {
					windowComp = domkitConstrucor(new HSprite(Assets.ui, eregFileName.matched(1)).tile, Std.int(nineSlice.x), Std.int(nineSlice.y),
						Std.int(nineSlice.width), Std.int(nineSlice.height), win);
					windowComp.window.bringOnTopOfALL = bringOnTopOfALL;
					windowComp.window.clampInScreen = clampInScreen;
					windowComp.window.onPush = ( e ) -> {
						bringOnTopOfALL();
					};
					windowComp.window.onDrag.add(( deltaX, deltaY ) -> {
						@:privateAccess if (Player.inst != null && win.parent != Player.inst.ui) Player.inst.ui.add(win, Player.inst.ui.children.length);
						win.x += deltaX;
						win.y += deltaY;
						clampInScreen();
					});
					windowComp.window.toggleVisible = toggleVisible;
				} else
					throw "bad logic";
			default:
				throw "bad logic";
		}
	}
}
