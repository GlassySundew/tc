package en;

import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends dn.Process {
	public static var ALL:Array<Item> = [];

	public var spr:HSprite;

	var interactive:h2d.Interactive;
	var textLabel:TextLabel;
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
		interactive.onOver = function(e:hxd.Event) {
			textLabel = new TextLabel(Left, "Iron Ore", Assets.fontPixel, Const.UI_SCALE);
			textLabel.x = Boot.inst.s2d.mouseX + 10;
			textLabel.y = Boot.inst.s2d.mouseY + 10;
		}
		interactive.onOut = function(e:hxd.Event) {
			textLabel.dispose();
		}
	}

	override function update() {
		super.update();
		if (textLabel != null && textLabel.disposed == false) {
			textLabel.x = Boot.inst.s2d.mouseX + 20;
			textLabel.y = Boot.inst.s2d.mouseY + 10;
		}
	}
}
