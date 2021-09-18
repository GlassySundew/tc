package ui.domkit;

import hxd.Event;
import cherry.soup.EventSignal.EventSignal1;
import ui.domkit.WindowComp.WindowCompI;
import h2d.domkit.Object;
import h2d.Flow;

class CraftingComp extends Flow implements h2d.domkit.Object implements WindowCompI {
    
    static var SRC = 
        <crafting-comp>
            <window(backgroundTile, bl, bt, br, bb) public id="window" layout="vertical">
                <flow class="content_flow">
                    <flow class="scrollable" public id="scrollable" layout="vertical" />
                    <flow class="scroll_bar" public id="scroll_bar"  >
                    </flow>
                </flow>
                </window>
        </crafting-comp> ;
    public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<h2d.Object>) {
        super(parent);

		initComponent();    

        window.makeCloseButton();
        window.makeDragable();

        window.style.load(hxd.Res.domkit.crafting);
        onBeforeReflow();
    }
    
    override function onBeforeReflow() {
        scroll_bar.minHeight = scroll_bar.maxHeight = scrollable.innerHeight;
    }
}