package ui;

import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.Tile;
import ch2.ui.EventInteractive;

class SecondaryMenu extends Object {
	var exitInteractive : EventInteractive;
	var overlayFlow : Flow;

	public function new( ?parent : Object ) {
		super(parent);
		overlayFlow = new Flow();
		@:privateAccess parent.addChildAt(overlayFlow, parent.children.length - 1);

		overlayFlow.minHeight = hScaled;
		overlayFlow.minWidth = wScaled;
		overlayFlow.backgroundTile = Tile.fromColor(0x000000, 1, 1, 0.6);

		exitInteractive = new EventInteractive(Util.wScaled, Util.hScaled, overlayFlow);

		exitInteractive.onClickEvent.add(( _ ) -> {
			remove();
		});
		exitInteractive.cursor = Default;

		try {
			cast(parent, Flow).getProperties(overlayFlow).isAbsolute = true;
		}
		catch( e:Dynamic ) {}
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		overlayFlow.x = -parent.x;
		overlayFlow.y = -parent.y;
	}

	override function onRemove() {
		super.onRemove();
		overlayFlow.remove();
		exitInteractive.remove();
	}
}
