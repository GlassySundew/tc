package ui.domkit;

import dn.heaps.slib.HSprite;
import en.player.Player;
import ui.domkit.WindowComp.WindowCompI;
import hxd.res.Resource;
import h2d.Tile;
import hxd.Event;
import cherry.soup.EventSignal.EventSignal1;
import hxd.Res;
import h2d.Object;
import h2d.Flow;
import ui.domkit.WindowComp.WindowCompI;

@:uiCoomp("recipe-comp")
class RecipeComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	public var onWheel : EventSignal1<Event> = new EventSignal1();
	public var onOver : EventSignal1<Event> = new EventSignal1();
	public var onOut : EventSignal1<Event> = new EventSignal1();

	public dynamic function craft() {}

	static var sheet : Resource;

	var iconSpr : HSprite;

	public var recipe : Data.Recipe;

	static var SRC =
	     <recipe-comp>
		    <window(backgroundTile, bl, bt, br, bb) public id="window" layout="horizontal">
		        <bitmap src={iconSpr.tile} class="icon" />
		        <flow class="craft_button" public id="craft_button" />
		    </window>
		</recipe-comp>
		;

	public function new( backgroundTile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, ?parent : Null<Object>, rest : haxe.Rest<Dynamic> ) {
		super(parent);
		recipe = rest[0];

		iconSpr = new HSprite(
			Assets.items,
			recipe.item_icon.atlas_name
		);

		if ( sheet == null ) sheet = Res.domkit.recipe;

		initComponent();

		window.style.load(sheet);

		enableInteractive = true;

		interactive.onWheel = ( e ) -> {
			onWheel.dispatch(e);
		}
		interactive.onOver = ( e ) -> {
			onOver.dispatch(e);
		};
		interactive.onOut = ( e ) -> {
			onOut.dispatch(e);
		};

		var craft_but0 = new HSprite(Assets.ui, "craft_but0");
		var craft_but1 = new HSprite(Assets.ui, "craft_but1");
		var craft_but2 = new HSprite(Assets.ui, "craft_but2");

		var craftButton = new ui.Button([craft_but0.tile, craft_but1.tile, craft_but2.tile], craft_button);

		craftButton.onClickEvent.add(( e ) -> craft());

		craftButton.onOverEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.lockBelt());
		craftButton.onOutEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.unlockBelt());
	}
}
