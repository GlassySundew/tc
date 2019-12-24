package en.player;

import haxe.io.Bytes;
import h2d.Bitmap;
import h2d.ScaleGrid;

class Inventory extends dn.Process {
	public static var inst:Inventory;

	public var items:Array<Item> = [];

	public var gridWidth = 6;
	public var gridHeight = 6;

	var invGridBeginX = 0;
	var invGridBeginY = 0;

	var ca:dn.heaps.Controller.ControllerAccess;
	var base:ScaleGrid;

	public function new() {
		super(Main.inst);
		inst = this;
		ca = Main.inst.controller.createAccess("inventory");

		// parsing pure red color (0x0ffff0000) as a top left point of grid start
		var bitmap = hxd.Res.inventory.toBitmap();
		for (i in 0...bitmap.height)
			for (j in 0...bitmap.width)
				if (bitmap.getPixel(j, i) == 0xffff0000) {
					invGridBeginX = j;
					invGridBeginY = i;
					// replacing red point with a background pixel from j-1, i-1
					bitmap.setPixel(j, i, bitmap.getPixel(j - 1, i - 1));
				}

		base = new h2d.ScaleGrid(h2d.Tile.fromBitmap(bitmap), 17, 20, Boot.inst.s2d);
		base.visible = !base.visible;
		base.setScale(Const.UI_SCALE);

		new ui.TextLabel(Middle, "Inventory", Assets.fontPixel, 1, Std.int(base.tile.width * 2), base);

		items.push(new en.items.Ore(invGridBeginX, invGridBeginY, Iron, base));
	}

	function recenter() {
		base.x = (Boot.inst.s2d.width >> 1) - base.width * base.scaleX / 2;
		base.y = (Boot.inst.s2d.height >> 1) - base.height * base.scaleY / 2;
	}

	override function update() {
		super.update();
		if (ca.isPressed(LT)) {
			base.visible = !base.visible;
			recenter();
		}
	}
}
