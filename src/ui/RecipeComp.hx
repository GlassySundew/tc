package ui;

import hxd.res.Resource;
import h2d.Tile;
import hxd.Event;
import cherry.soup.EventSignal.EventSignal1;
import hxd.Res;
import h2d.Object;
import h2d.Flow;
import ui.WindowComp.WindowCompI;

@:uicomp("recipe-comp")
class RecipeComp extends Flow implements h2d.domkit.Object implements WindowCompI {
    public var onWheel : EventSignal1<Event> = new EventSignal1();
    
    static var sheet: Resource;
    var iconSpr:Tile;

    static var SRC = 
        <recipe-comp>
            <window(backgroundTile, bl, bt, br, bb) public id="window" layout="horizontal">
                <bitmap src={iconSpr} class="icon" />
                <flow class="craft_button" public id="craft_button" />
                </window>
        </recipe-comp>
            ;   
	public function new( recipe : Data.Recipes, backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<Object> ) {
		super(parent);
        iconSpr = new HSprite(Assets.items, recipe.item_icon.atlas_name).tile;

        if ( sheet == null ) sheet = Res.domkit.recipe;
        
		initComponent();

		window.style.load(sheet);

        enableInteractive = true;
        interactive.onWheel = (e) -> onWheel.dispatch(e);

        interactive.onFocus Add

        var craft_but0 = new HSprite(Assets.ui, "craft_but0");
		var craft_but1 = new HSprite(Assets.ui, "craft_but1");
		var craft_but2 = new HSprite(Assets.ui, "craft_but2");

		var craftButton = new ui.Button([craft_but0.tile, craft_but1.tile, craft_but2.tile], craft_button);


	}
}