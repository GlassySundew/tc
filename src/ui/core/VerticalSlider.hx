package ui.core;

import dn.legacy.Color;
import hxd.Event;
import h2d.RenderContext;
import h2d.ScaleGrid;
import ch2.ui.EventInteractive;

class VerticalSlider extends EventInteractive {
	public var tile : h2d.Tile;
	public var cursorObj : ScaleGrid;
	public var minValue(default, set) : Float = 0;
	public var maxValue(default, set) : Float = 1;
	public var value(default, set) : Float = 0;

	public function new( ?width : Int = 50, ?height : Int = 10, cursorObj : ScaleGrid, ?parent ) {
		super(width, height, parent);

		tile = h2d.Tile.fromColor(Color.addAlphaI(0x00000000), width, height, 0);
		this.cursorObj = cursorObj;
		addChild(cursorObj);
	}

	function set_minValue( v ) {
		if ( value < v ) value = v;
		return minValue = v;
	}

	function set_maxValue( v ) {
		if ( value > v ) value = v;
		return maxValue = v;
	}

	function set_value( v ) {
		if ( v < minValue ) v = minValue;
		if ( v > maxValue ) v = maxValue;
		return value = v;
	}

	override function getBoundsRec( relativeTo, out, forSize ) {
		super.getBoundsRec(relativeTo, out, forSize);
		if ( forSize ) addBounds(relativeTo, out, 0, 0, width, height);
		if ( tile != null ) addBounds(relativeTo, out, tile.dx, tile.dy, tile.width, tile.height);
		if ( cursorObj != null ) addBounds(relativeTo, out, cursorObj.y + getDy(), cursorObj.y, cursorObj.width, cursorObj.height);
	}

	override function draw( ctx : RenderContext ) {
		super.draw(ctx);
		if ( tile.height != Std.int(height) ) tile.setSize(Std.int(width), tile.height);
		emitTile(ctx, tile);
		var px = getDy();
		cursorObj.y = px;
	}

	var handleDX = 0.0;

	inline function getDy() {
		return Math.abs(Math.round((value - minValue) * (height - cursorObj.height) / (maxValue - minValue)));
	}

	inline function getValue( eRelY : Float ) : Float {
		return ((eRelY - handleDX) / (height - cursorObj.height)) * (maxValue - minValue) + minValue;
	}

	override function handleEvent( e : hxd.Event ) {
		super.handleEvent(e);
		if ( e.cancel ) return;
		switch( e.kind ) {
			case EPush:
				var dy = getDy();
				handleDX = e.relY - dy;

				// If clicking the slider outside the handle, drag the handle
				// by the center of it.
				if ( handleDX - cursorObj.tile.dy < 0 || handleDX - cursorObj.tile.dy > cursorObj.height ) {
					handleDX = cursorObj.height * 0.5;
				}

				onChange();

				var scene = scene;
				value = getValue(e.relY);
				function capture( e : Event ) {
					if ( this.scene != scene || e.kind == ERelease ) {
						scene.stopCapture();
						return;
					}
					value = getValue(e.relY);
					onChange();
				}

				capture(e);
				startCapture(capture);

			default:
		}
	}

	public dynamic function onChange() {}
}
