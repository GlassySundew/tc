package ui;

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
		visible = true;
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

				handleDX = e.relX;
				handleDY = e.relY;

				var scene = scene;
				startCapture(function ( e ) {
					if ( this.scene != scene || e.kind == ERelease ) {
						scene.stopCapture();
						return;
					}
					var deltaX = (e.relX - handleDX) / 8;
					var deltaY = (e.relY - handleDY) / 8;
					if ( onDrag != null ) onDrag.dispatch(deltaX - deltaX % 0.5, deltaY - deltaY % 0.5);
				});

			default:
		}
		super.handleEvent(e);
	}
}
