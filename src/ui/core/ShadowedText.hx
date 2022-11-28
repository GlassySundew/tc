package ui.core;

import util.Assets;
import h2d.col.Bounds;
import dn.heaps.filter.PixelOutline;
import h2d.Drawable;
import h2d.Font;
import h2d.Object;

class ShadowedText extends h2d.Text {

	public function new( ?font : Font, ?parent : h2d.Object ) {
		super( font == null ? Assets.fontPixel : font, parent );

		smooth = false;
		addTextOutlineTo( this );
 
		y++; // because top outlined pixel is not drawn
	}

	public static function addTextOutlineTo( drawable : Drawable ) {
		var outline = new PixelOutline( 0x000000, 0.85 );
		drawable.filter = outline;
	}

	override function get_textHeight():Float {
		return super.get_textHeight() + 1;
	}

	override function getBoundsRec( relativeTo : Object, out : Bounds, forSize : Bool ) {
		super.getBoundsRec( relativeTo, out, forSize );
		addBounds( relativeTo, out, x, y, 0, -5 );
	}

}
