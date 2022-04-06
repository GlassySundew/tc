package ui;

import dn.heaps.filter.PixelOutline;
import h2d.Drawable;
import h2d.Object;
import h2d.filter.Outline;
import h2d.Font;

class ShadowedText extends h2d.Text {
	public function new( ?font : Font, ?parent : h2d.Object ) {
		super( font == null ? Assets.fontPixel : font, parent );

		smooth = false;
		addTextOutlineTo( this );
	}

	public static function addTextOutlineTo( drawable : Drawable ) {
		var outline = new PixelOutline( 0x000000, 0.8 );
		drawable.filter = outline;
	}
}
