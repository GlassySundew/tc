package ui.player;

import en.player.Player;
import h2d.Drawable;
import hxd.Event;
import ui.s2d.EventInteractive;

// Невидимый Interactive, за который можно потянуть всё окно
class Dragable extends EventInteractive {
	var handleDX = 0.0;
	var handleDY = 0.0;
	var onDrag : Float -> Float -> Void;

	public function new(width, height, ?onDrag : Float -> Float -> Void, ?parent, ?shape) {
		super(width, height, parent, shape);
		this.onDrag = onDrag;
	}

	override function handleEvent(e : Event) {
		super.handleEvent(e);

		if ( e.cancel ) return;
		switch( e.kind ) {
			case EPush:
				Player.inst.ui.add(parent, Const.DP_UI);
				handleDX = e.relX;
				handleDY = e.relY;
				if ( onDrag != null ) onDrag(0, 0);

				// If clicking the slider outside the handle, drag the handle
				// by the center of it.
				var followCursor = () -> {
					parent.x = hxd.Math.clamp(Boot.inst.s2d.mouseX / Const.SCALE - handleDX - x, 0,
						Game.inst.w() / Const.SCALE /*- cast(parent, HSprite).tile.width*/);
					parent.y = hxd.Math.clamp(Boot.inst.s2d.mouseY / Const.SCALE - handleDY - y, 0,
						Game.inst.h() / Const.SCALE /*- cast(parent, HSprite).tile.height*/);
				}

				var scene = scene;
				startCapture(function(e) {
					if ( this.scene != scene || e.kind == ERelease ) {
						scene.stopCapture();
						return;
					}
					if ( onDrag != null ) onDrag(((e.relX - handleDX) / 8.5), ((e.relY - handleDY) / 8.5));
				});

			default:
		}
	}
}
