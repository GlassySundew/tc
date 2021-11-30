package ui.domkit;

import ui.domkit.WindowComp.WindowCompI;
import h2d.Flow;

@:uiComp("scrollbar")
class ScrollbarComp extends Flow implements h2d.domkit.Object implements WindowCompI {
    
    static var SRC = 
        <scrollbar public id="scrollbar" class="scrollbar-comp" fill-height="true">
            <window(backgroundTile, bl, bt, br, bb) public id="window" layout="vertical" >

            </window>
        </scrollbar>;
    
    public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<h2d.Object>, rest : haxe.Rest<Dynamic>) {
        super(parent);
		initComponent();
        
        window.style.load(hxd.Res.domkit.scrollbar);
    }
}