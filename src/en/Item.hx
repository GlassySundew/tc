package en;

import h2d.Scene;
import h2d.RenderContext;
import en.player.Player;
import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends Object {
	public var spr:HSprite;

	var displayText:String = "";

	public var interactive:h2d.Interactive;

	var textLabel:TextLabel;
	var bitmap:Bitmap;

	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		super(parent);

		if (spr == null)
			spr = new HSprite(Assets.items, this);

		spr.tile.getTexture().filter = Nearest;
		spr.setCenterRatio();
		interactive = new Interactive(spr.tile.width, spr.tile.height, spr);

		interactive.onOver = function(e:hxd.Event) {
			textLabel = new TextLabel(displayText, Assets.fontPixel, Boot.inst.s2d);
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
				// if (swapItem != null)
				// 	swapItem.spr.scale(1 / 2);
				Game.inst.player.inventory.invGrid.removeItem(this, swapItem);
				Game.inst.player.inventory.belt.invGrid.removeItem(this, swapItem);
				Boot.inst.s2d.addChild(this);
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
		spr.remove();
		interactive.remove();
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		if (textLabel != null) {
			textLabel.x = Boot.inst.s2d.mouseX + 20;
			textLabel.y = Boot.inst.s2d.mouseY + 20;
		}
		interactive.width = spr.tile.width;
		interactive.height = spr.tile.height;

		interactive.x = -spr.tile.width / 2;
		interactive.y = -spr.tile.height / 2;

		setScale(Std.isOfType(parent, Scene) ? 2 : 1);
	}
}
