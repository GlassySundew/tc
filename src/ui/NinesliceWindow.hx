package ui;

import h2d.Object;
import h2d.Tile;
import haxe.Constraints.Constructible;

typedef NinesliceConf = {
	var atlasName : String;
	var bl : Int;
	var bt : Int;
	var br : Int;
	var bb : Int;
}

class NinesliceWindow extends Window {
	@:s var background : String;
	var rest : haxe.Rest<Dynamic>;
	@:s var childType : String;

	public function new(
		?background : String = "window",
		childType : Class<Dynamic>,
		?parent : Null<h2d.Object>,
		... rest : Dynamic
	) {
		this.rest = rest;
		this.background = background;
		this.childType = StringTools.replace('$childType', '$', '');
		
		super(parent);
	}

	public override function initLoad( ?parent : Null<h2d.Object> ) {
		var nineSliceConf = nineSliceFromConf(background);
		windowComp = Type.createInstance(Type.resolveClass(childType), [
			new HSprite(Assets.ui, nineSliceConf.atlasName).tile,
			nineSliceConf.bl,
			nineSliceConf.bt,
			nineSliceConf.br,
			nineSliceConf.bb,
			win,
			rest
		]);

		windowComp.window.bringOnTopOfALL = bringOnTopOfALL;
		windowComp.window.clampInScreen = clampInScreen;
		windowComp.window.onPush = ( e ) -> {
			bringOnTopOfALL();
		};
		windowComp.window.onDrag.add(( x, y ) -> {
			win.x += x;
			win.y += y;
			clampInScreen();
		});
		windowComp.window.toggleVisible = toggleVisible;

		super.initLoad(parent);
	}
}