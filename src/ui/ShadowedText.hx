package ui;

import h2d.Drawable;
import h2d.Object;
import h2d.filter.Outline;
import h2d.Font;

class ShadowedText extends h2d.Text {
	public function new( font : Font, ?parent : h2d.Object ) {
		super(font, parent);

		addTextOutlineTo(this);
	}

	public static function addTextOutlineTo( drawable : Drawable ) {
		var outline = new Outline(0.3, Color.rgbaToInt({
			r : 1,
			g : 1,
			b : 1,
			a : 100
		}), 0.5);
		drawable.filter = outline;
	}
}
