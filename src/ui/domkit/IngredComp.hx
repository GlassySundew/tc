package ui.domkit;

import util.Assets;
import dn.heaps.slib.HSprite;
import h2d.Flow;
import h2d.Tile;
import h2d.domkit.Object;
import hxd.Res;
import hxd.res.Resource;
import ui.domkit.WindowComp.WindowCompI;
import util.Const;

@:uiComp( "ingred-comp" )
class IngredComp extends Flow implements Object implements WindowCompI {

	var iconSpr : HSprite;
	var amount : String;

	static var SRC =
	    <ingred-comp class="ingred-comp">
		    <window(backgroundTile, bl, bt, br, bb) public id="window">
		        <bitmap src={iconSpr.tile} class="icon" />
		        <textLabel(Std.string(ingred.amount)) class="amount-label" public id="amount-label"
		            scale={{y : 1 / Const.UI_SCALE, x : 1 / Const.UI_SCALE}} />
		        </window>
		</ingred-comp>;

	static var sheet : Resource;

	var ingred : Data.Recipe_ingred;

	/**
		@param rest : Data.Recipe_ingred type, displayed icon
	**/
	public function new( 
		backgroundTile : h2d.Tile, 
		bl : Int, 
		bt : Int, 
		br : Int, 
		bb : Int, 
		?parent : Null<h2d.Object>, 
		rest : haxe.Rest<Dynamic>
	) {
		ingred = rest[0];
		iconSpr = new HSprite( Assets.items, ingred.item.atlas_name );

		amount = Std.string( ingred.amount );

		super( parent );
		if ( sheet == null ) sheet = Res.domkit.ingred;
		initComponent();

		window.style.load( sheet );
	}
}
