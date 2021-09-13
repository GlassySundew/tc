package ui;

import h2d.Flow;
import h2d.RenderContext;
import h2d.Object;
import h2d.col.Bounds;
import ch2.ui.ScrollArea;

class FixedScrollArea extends ScrollArea {
	var fillWidth : Bool;
	var fillHeight : Bool;

	public function new( width : Int, height : Int, scrollStep : Int = 16, ?fillWidth = false, ?fillHeight = false, ?bounds : Bounds, ?parent : Object ) {
		super(width, height, scrollStep, bounds, parent);
		this.fillHeight = fillHeight;
		this.fillWidth = fillWidth;
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		try {
			if ( fillHeight ) height = cast(parent, Flow).maxHeight;
			if ( fillWidth ) width = cast(parent, Flow).maxWidth;
		} catch( e ) {}
	}

	override function drawRec( ctx : h2d.RenderContext ) @:privateAccess {
		if ( !visible ) return;
		// fallback in case the object was added during a sync() event and we somehow didn't update it
		if ( posChanged ) {
			// only sync anim, don't update() (prevent any event from occuring during draw())
			// if( currentAnimation != null ) currentAnimation.sync();
			calcAbsPos();
			for ( c in children ) c.posChanged = true;
			posChanged = false;
		}

		var x1 = absX + scrollX * 2;
		var y1 = absY + scrollY * 2;

		var x2 = width * matA + height * matC + x1;
		var y2 = width * matB + height * matD + y1;

		var tmp;
		if ( x1 > x2 ) {
			tmp = x1;
			x1 = x2;
			x2 = tmp;
		}

		if ( y1 > y2 ) {
			tmp = y1;
			y1 = y2;
			y2 = tmp;
		}

		ctx.flush();
		ctx.pushRenderZone(x1, y1, x2 - x1, y2 - y1);
		objDrawRec(ctx);
		ctx.flush();
		ctx.popRenderZone();
	}
}
