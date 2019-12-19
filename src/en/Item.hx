package en;

import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends dn.Process {
	public static var ALL:Array<Item> = [];

	public var spr:HSprite;

	var interactive:h2d.Interactive;
	var bitmap:Bitmap;

	public var x:Float;
	public var y:Float;

	var width = 16;
	var height = 16;

	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		super(Main.inst);
		ALL.push(this);

		this.x = spr.x = x;
		this.y = spr.y = y;

		if (spr == null)
			spr = new HSprite(Assets.items, parent);

		spr.tile.getTexture().filter = Nearest;

		interactive = new Interactive(width, height, spr);
	}
}
