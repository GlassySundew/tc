package ui.domkit;

import util.Assets;
import ui.NinesliceWindow.NinesliceConf;
import ui.domkit.WindowComp.WindowCompI;
import h2d.Flow;
import util.Util;
import dn.heaps.slib.HSprite;

class NavigationComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	var navWinConf : NinesliceConf;

	static var SRC = 
        <navigation-comp>
            <window(backgroundTile, bl, bt, br, bb) public id="window" layout="vertical">
                <window(new HSprite(Assets.ui, navWinConf.atlasName).tile, navWinConf.bl, navWinConf.bt, navWinConf.br,
                    navWinConf.bb) public id="nav_win" class="scrollable" />
                </window>
        </navigation-comp>;
        
        
    public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<h2d.Object>, rest : haxe.Rest<Dynamic> ) {
		super(parent);
        navWinConf = Util.nineSliceFromConf("nav_win");
		
        initComponent();

        nav_win.windowLabel.remove();
        
		window.makeCloseButton();
		window.makeDragable();

		window.style.load(hxd.Res.domkit.navigation);

	}
}
