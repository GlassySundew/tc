package ui.domkit;

import cherry.soup.EventSignal.EventSignal2;
import cherry.soup.EventSignal.EventSignal0;
import hxd.Event;
import en.player.Player;
import h2d.domkit.Style;
import h2d.RenderContext;
import h2d.ScaleGrid;
import h2d.Flow;

interface WindowCompI {
	public var window : WindowComp;
}

/**background nineslice**/
@:uiComp("window")
class WindowComp extends Flow implements h2d.domkit.Object implements WindowCompI {
	public var window : WindowComp;
	public var style : Style;
	public var bringOnTopOfALL : Void -> Void;
	public var clampInScreen : Void -> Void;

    /** dragable callbacks **/
	public var onDrag : EventSignal2<Float, Float> = new EventSignal2();
	public var onPush : Event -> Void;
	public var toggleVisible : Void -> Void;
	
	static var SRC = 
		<window class="window_root" layout="vertical">
			<flow class="dragable_comp" public id="dragable_comp" />
			<flow class="close_button" public id="close_button" />
			<textLabel("window") class="windowLabel" public id="windowLabel" />
		</window>;
	public function new( tile : h2d.Tile, bl : Int, bt : Int, br : Int, bb : Int, parent : Null<h2d.Object> ) {
		super(parent);
		initComponent();
		
		window = this;

        needReflow = true;
        
        borderLeft = bl;
        borderTop = bt;
        borderRight = br;
        borderBottom = bb;


		// background = new ScaleGrid(tile, bl, bt, br, bb, window);
        backgroundTile = tile;

        needReflow = true;


        
        // window.addChildAt(background, 0);
		// window.getProperties(window.background).isAbsolute = true;		

		style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.window, true);
		style.addObject(this);

		#if debug
		style.allowInspect = true;
		#end
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		dragable_comp.minWidth = window.innerWidth;
	}

	public function makeDragable() {
		dragable_comp.fillWidth = true;
		var dragable = new Dragable(0, 0,
			(x, y) -> onDrag.dispatch(x, y), 
			(e) -> onPush(e), true, true);
		dragable_comp.addChild(dragable);
		dragable_comp.getProperties(dragable).isAbsolute = true;
	}

	public function makeCloseButton( ?atlasName:String = "close_button_inventory" ) {
		var close_button_inventory0 = new HSprite(Assets.ui, '${atlasName}0');
		var close_button_inventory1 = new HSprite(Assets.ui, '${atlasName}1');
		var close_button_inventory2 = new HSprite(Assets.ui, '${atlasName}2');

		var closeButton = new Button([
			close_button_inventory0.tile,
			close_button_inventory1.tile,
			close_button_inventory2.tile
		]);

		closeButton.onClickEvent.add(( _ ) -> {
			toggleVisible();
		});

		close_button.addChild(closeButton);
	}
	

}
