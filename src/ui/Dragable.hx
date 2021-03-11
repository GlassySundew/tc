package ui;

import cherry.soup.EventSignal.EventSignal2;
import en.player.Player;
import h2d.Drawable;
import hxd.Event;
import ui.s2d.EventInteractive;

// Невидимый Interactive, за который можно потянуть всё окно
class Dragable extends EventInteractive {
	var handleDX = 0.0;
	var handleDY = 0.0;

	public var onDrag : EventSignal2<Float, Float> = new EventSignal2();

	public function new(width, height, ?onDrag : Float -> Float -> Void, ?parent, ?shape) {
		super(width, height, parent, shape);

		if ( onDrag != null ) this.onDrag.add(onDrag);
	}

	override function handleEvent(e : Event) {
		super.handleEvent(e);

		if ( e.cancel ) return;
		switch( e.kind ) {
			case EPush:
				handleDX = e.relX;
				handleDY = e.relY;
				if ( onDrag != null ) onDrag.dispatch(0, 0);

				var scene = scene;
				startCapture(function(e) {
					if ( this.scene != scene || e.kind == ERelease ) {
						scene.stopCapture();
						return;
					}
					if ( onDrag != null ) onDrag.dispatch(((e.relX - handleDX) / 8.5), ((e.relY - handleDY) / 8.5));
				});

			default:
		}
	}
}
