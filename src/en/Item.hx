package en;

import h2d.Scene;
import h2d.RenderContext;
import en.player.Player;
import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

class Item extends Object {
	public var ent:Entity;
	public var spr:HSprite;
	public var interactive:h2d.Interactive;

	var displayText:String = "";
	var textLabel:TextLabel;
	var bitmap:Bitmap;

	inline public function isInSlot():Bool
		return Std.is(parent, h2d.Interactive);

	inline public function isInCursor():Bool
		return Std.is(parent, Scene);

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
			// Picking up the item into the player's holdItem (cursor)
			if (Player.inst.inventory.base.visible) {
				textLabel.dispose();
				Player.inst.inventory.belt.deselectCells();
				Player.inst.enableGrids();

				var swapItem = Game.inst.player.holdItem;
				swapItem = swapItem == this ?null:swapItem;
				
				Game.inst.player.holdItem = this;
				if (Game.inst.player.inventory.belt.invGrid.removeItem(this, swapItem) == null)
					Game.inst.player.inventory.invGrid.removeItem(this, swapItem);

				Boot.inst.s2d.addChild(this);
				scaleX = scaleY = 2;
			} else if (isInSlot()) {
				// Selecting item in the belt if inventory is hidden
				var beltGrid = Player.inst.inventory.belt.invGrid.interGrid;
				for (i in beltGrid) {
					var cout = 0;
					for (j in i) {
						if (j.item == this)
							Player.inst.inventory.belt.selectCell(cout + 1);
						cout++;
					}
				}
			}
		}
	}

	public function dispose() {
		spr.remove();
		interactive.remove();
		trace("disposed");
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
	}
}
