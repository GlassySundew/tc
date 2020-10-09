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

	public function new(?type:ItemsKind, ?parent:Object) {
		super(parent);
		if (spr == null) {
			spr = new HSprite(Assets.items, this);
			if (type != null) {
				spr.set(Data.items.get(type).atlas_name);
				displayText = Data.items.get(type).display_name;
			}
		}
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
			if (Player.inst.ui.inventory.sprInv.visible) {
				textLabel.dispose();
				Player.inst.ui.inventory.belt.deselectCells();
				Player.inst.enableGrids();
				var swapItem = Game.inst.player.holdItem;
				swapItem = swapItem == this ?null:swapItem;

				Player.inst.holdItem = this;
				Player.inst.ui.inventory.invGrid.removeItem(this, swapItem);

				Boot.inst.s2d.addChild(this);
				scaleX = scaleY = 2;
			} else if (isInSlot()) {
				// Selecting item in the belt if inventory is hidden
				var beltGrid = Player.inst.ui.inventory.invGrid.interGrid[Player.inst.ui.inventory.invGrid.interGrid.length - 1];
				var cout = 1;
				for (i in beltGrid) {
					if (i.item == this)
						Player.inst.ui.inventory.belt.selectCell(cout);
					cout++;
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
