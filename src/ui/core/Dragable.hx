package ui.core;

import h2d.col.Point;
import h2d.Flow;
import h2d.RenderContext;
import cherry.soup.EventSignal.EventSignal2;
import en.player.Player;
import h2d.Drawable;
import hxd.Event;
import ch2.ui.EventInteractive;

// Невидимый Interactive, за который можно потянуть всё окно
class Dragable extends EventInteractive {
	var handleDX = 0.0;
	var handleDY = 0.0;

	var fillWidth : Bool;
	var fillHeight : Bool;

	public var onDrag : EventSignal2<Float, Float> = new EventSignal2();

	public function new( width, height, ?onDrag : Float -> Float -> Void, ?onPush : Event -> Void, ?parent, ?shape, ?fillWidth : Bool = false,
		?fillHeight : Bool = false ) {
		super(width, height, parent, shape);
		this.fillWidth = fillWidth;
		this.fillHeight = fillHeight;
		if ( onPush != null ) this.onPush = onPush;
		if ( onDrag != null ) this.onDrag.add(onDrag);
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		try {
			if ( fillHeight ) height = cast(parent, Flow).innerHeight;
			if ( fillWidth ) width = cast(parent, Flow).innerWidth;
		} catch( e ) {}
	}

	override function handleEvent( e : Event ) {
		if ( e.cancel ) return;
		switch( e.kind ) {
			case EPush:
				var mouseHandle = new Point(Boot.inst.s2d.mouseX, Boot.inst.s2d.mouseY);

				var scene = scene;
				startCapture(function ( e ) {
					if ( this.scene != scene || e.kind == ERelease ) {
						scene.stopCapture();
						return;
					}

					var deltaX = (Boot.inst.s2d.mouseX - mouseHandle.x) / Const.UI_SCALE;
					var deltaY = (Boot.inst.s2d.mouseY - mouseHandle.y) / Const.UI_SCALE;
					mouseHandle = new Point(Boot.inst.s2d.mouseX, Boot.inst.s2d.mouseY);

					if ( onDrag != null ) onDrag.dispatch(deltaX - deltaX % (1 / Const.UI_SCALE), deltaY - deltaY % (1 / Const.UI_SCALE));
				});

			default:
		}
		super.handleEvent(e);
	}
}
