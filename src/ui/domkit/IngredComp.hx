package ui.domkit;

import h2d.Tile;
import hxd.Res;
import hxd.res.Resource;
import h2d.Flow;
import ui.domkit.WindowComp.WindowCompI;
import h2d.domkit.Object;

@:uiComp("ingred-comp")
class IngredComp extends Flow implements Object implements WindowCompI {
    var iconSpr : Tile;
    var amount : String;
    static var SRC = 
        <ingred-comp class="ingred-comp">
            <window(backgroundTile, bl, bt, br, bb) public id="window">
                <bitmap src={iconSpr} class="icon" />
                <textLabel(Std.string(ingred.amount)) class="amount-label" public id="amount-label"
                    scale={{y : 1 / Const.SCALE, x : 1 / Const.SCALE}} />

                </window>
        </ingred-comp>;
    static var sheet : Resource;

    public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ingred : Data.Recipes_ingreds, ?parent : Null<h2d.Object> ) {
        iconSpr = new HSprite(Assets.items, ingred.item.atlas_name).tile;
        amount = Std.string(ingred.amount);
        
        super(parent);  
        if ( sheet == null ) sheet = Res.domkit.ingred;
        initComponent();
        
        window.style.load(sheet);
    }
}