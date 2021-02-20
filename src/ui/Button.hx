package ui;

import ui.CustomButton.ButtonFlags;
import ui.CustomButton.ButtonState;
import ui.CustomButton.IButtonStateView;
import h2d.Object;
import h2d.RenderContext;
import h2d.Tile;

class Button extends CustomButton implements IButtonStateView {
	var curr : Tile;
	var states : Array<Tile>;
	var doSfx : Bool;

	public static var shiftDown : Bool = true;

	public function new(states : Array<Tile>, ?parent) {
		this.states = states;
		processStates(states);
		super(states[0].width, states[0].height, parent, null, [this]);
	}

	inline function processStates(s : Array<Tile>) {
		if ( s.length == 1 ) s.push(s[0]);
		if ( s.length == 2 ) {
			s.push(s[1].clone());
			// if (shiftDown) s[2].dy++;
		}
		s.insert(1, s[1]);
	}

	public function setState(state : ButtonState, flags : ButtonFlags) {
		curr = states[state];
	}

	override function getBoundsRec(relativeTo : Object, out : h2d.col.Bounds, forSize : Bool) {
		super.getBoundsRec(relativeTo, out, forSize);
		if ( curr != null ) addBounds(relativeTo, out, curr.dx, curr.dy, curr.width, curr.height);
	}

	override function draw(ctx : RenderContext) {
		emitTile(ctx, curr);
		super.draw(ctx);
	}
}
