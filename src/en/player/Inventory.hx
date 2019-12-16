package en.player;

import h2d.ScaleGrid;

class Inventory extends dn.Process {
	public static var inst:Inventory;

	var ca:dn.heaps.Controller.ControllerAccess;
	var base:ScaleGrid;

	public function new() {
		super(Main.inst);
		inst = this;

		ca = Main.inst.controller.createAccess("inventory");

		base = new h2d.ScaleGrid(hxd.Res.inventory.toTile().center(), 17, 20, Boot.inst.s2d);
		base.tileBorders = false;
		
		new ui.TextLabel(Middle, "Inventory", Assets.fontPixel, h2d.Tile.fromColor(0xFF, 32, 32), Std.int(base.width * 2), base);

		base.visible = !base.visible;

		base.setScale(144*(Math.PI / 180));
	}

	function recenter() {
		base.x = (Boot.inst.s2d.width >> 1) - base.width * base.scaleX / 2;	
		base.y = (Boot.inst.s2d.height >> 1) - base.height * base.scaleX / 2;
	}

	override function update() {
		super.update();
		if (ca.isPressed(LT)) {
			base.visible = !base.visible;
			recenter();
		}
	}
}
