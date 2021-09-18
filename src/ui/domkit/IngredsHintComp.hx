package ui.domkit;

import ui.domkit.WindowComp.WindowCompI;
import hxd.Res;
import hxd.res.Resource;
import h2d.domkit.Object;
import h2d.Flow;

@:uiComp("ingreds-hint-comp")
class IngredsHintComp extends Flow implements Object implements WindowCompI {
    static var SRC = 
        <ingreds-hint-comp class="ingreds-hint-comp">
            <window(backgroundTile, bl, bt, br, bb) public id="window" >
                <flow public id="ingreds_holder" class="ingreds_holder" layout="vertical" /> 
               </window>
        </ingreds-hint-comp>;

    static var sheet : Resource;

    public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<h2d.Object> ) {
        super(parent);  
        if ( sheet == null ) sheet = Res.domkit.ingreds_hint;
        initComponent();
     
        window.windowLabel.label = "Ingredients";

        window.style.load(sheet);
    }
}