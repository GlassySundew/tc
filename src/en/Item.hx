package en;

import en.player.Player;
import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends dn.Process {
	public static var ALL:Array<Item> = [];

	public var spr:HSprite;

	var displayText:String = "";

	public var interactive:h2d.Interactive;

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
		// Game.inst.root.add(spr, 1);
		spr.tile.getTexture().filter = Nearest;
		interactive = new Interactive(width, height, spr);
		interactive.x -= spr.tile.width / 2;
		interactive.y -= spr.tile.height / 2;

		interactive.onOver = function(e:hxd.Event) {
			textLabel = new TextLabel(Left, displayText, Assets.fontPixel, Const.UI_SCALE);
		}

		interactive.onOut = function(e:hxd.Event) {
			textLabel.dispose();
		}

		interactive.onPush = function(e:hxd.Event) {
			if (Player.inst.inventory.base.visible) {
				textLabel.dispose();
				Player.inst.inventory.belt.deselectCells();
				var swapItem = Game.inst.player.cursorItem;
				Game.inst.player.cursorItem = this;
				if (swapItem != null)
					swapItem.spr.scale(1 / 2);
				Game.inst.player.inventory.invGrid.removeItem(this, swapItem);
				Game.inst.player.inventory.belt.invGrid.removeItem(this, swapItem);
				Boot.inst.s2d.addChild(this.spr);
			} else {
				for (i in 0...Player.inst.inventory.belt.invGrid.interGrid.length) {
					if (Player.inst.inventory.belt.invGrid.interGrid[i][0].item == this) {
						Player.inst.inventory.belt.selectCell(i + 1);
					}
				}
			}
		}
	}

	public function dispose() {
		destroy();
		spr.remove();
		interactive.remove();
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
