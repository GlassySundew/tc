package en;

import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends dn.Process {
	public static var ALL:Array<Item> = [];

	public var spr:HSprite;

	var displayText:String = "";

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
		spr.setCenterRatio(.5, .5);

		interactive.x -= spr.tile.width / 2;
		interactive.y -= spr.tile.height / 2;

		interactive.onOver = function(e:hxd.Event) {
			textLabel = new TextLabel(Left, displayText, Assets.fontPixel, Const.UI_SCALE);
		}

		interactive.onOut = function(e:hxd.Event) {
			textLabel.dispose();
		}

		interactive.onPush = function(e:hxd.Event) {
			textLabel.dispose();

			var tempItem = Game.inst.player.holdItem;
			Game.inst.player.holdItem = this;
			if (tempItem != null)
				tempItem.spr.scale(1 / 2);
			Game.inst.player.inventory.invGrid.removeItem(this, tempItem);
			Game.inst.player.inventory.belt.invGrid.removeItem(this, tempItem);
			Boot.inst.s2d.addChild(this.spr);
		}
	}

	override function update() {
		super.update();
		if (textLabel != null && textLabel.disposed == false) {
			textLabel.x = Boot.inst.s2d.mouseX + 10;
			textLabel.y = Boot.inst.s2d.mouseY + 5;
		}
		spr.x = x;
		spr.y = y;
	}
}
