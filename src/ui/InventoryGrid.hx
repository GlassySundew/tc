package ui;

import h3d.scene.Object;
import h2d.ScaleGrid;
import hxd.Event;
import en.player.Player;

class InventoryCell extends h2d.Object {
	public var item(default, set):Item;
	public var inter:h2d.Interactive;

	inline function set_item(v:Item) {
		if (v != null) {
			// v.spr.scaleX = v.spr.scaleY = 1;
			// v.spr.scaleX = v.spr.scaleY = ((inter.parent == Std.downcast(inter.parent, ScaleGrid)) ? 1 : 3);
			inter.addChild(v);
			v.x = inter.width / 2;
			v.y = inter.height / 2;
			v.setScale(1);
		}

		return item = v;
	}

	public function new(width:Int, height:Int, ?parent:h2d.Object) {
		super(parent);
		inter = new h2d.Interactive(width, height, this);
		// inter.visible = false;
		inter.cursor = Default;
		inter.onPush = function(e:Event) {
			if (Game.inst.player.cursorItem != null && item == null) {
				item = Game.inst.player.cursorItem;
				Game.inst.player.cursorItem = null;
			}
		}
	}
}

class InventoryGrid extends h2d.Object {
	public static var ALL:Array<InventoryGrid> = [];

	var player(get, never):Player;

	inline function get_player()
		return Player.inst;

	public var interGrid:Array<Array<InventoryCell>>;

	public function new(x:Int, y:Int, width:Int, height:Int, horCells:Int, verCells:Int, xGap:Int, yGap:Int, ?parent:h2d.Object) {
		super(parent);
		ALL.push(this);
		interGrid = [for (i in 0...verCells) []];
		for (j in 0...horCells) {
			interGrid[j] = [];
			for (i in 0...verCells) {
				var tempInter = new InventoryCell(width, height, this);
				tempInter.inter.x = x + j * width + j * xGap;
				tempInter.inter.y = y + i * height + i * yGap;

				interGrid[j].push(tempInter);
			}
		}
	}

	public function dispose() {
		ALL.remove(this);

		for (i in interGrid)
			for (j in i) {
				j.inter.remove();
			}
	}

	public function disableGrid() {
		for (i in interGrid)
			for (j in i) {
				j.inter.cursor = Default;
			}
	}

	public function enableGrid() {
		for (i in interGrid)
			for (j in i) {
				if (j.item == null)
					j.inter.cursor = Button;
			}
	}

	public function getFreeSlot():InventoryCell {
		for (i in 0...interGrid.length)
			for (j in 0...interGrid[i].length)
				if (interGrid[j][i].item == null)
					return interGrid[j][i];
		for (i in player.inventory.belt.invGrid.interGrid)
			for (j in i)
				if (j.item == null)
					return j;
		return null;
	}

	public function giveItem(item:Item) {
		var slot = getFreeSlot();
		slot.item = item;
	}

	public function removeItem(item:Item, ?to:Null<Item>) {
		for (i in interGrid) {
			for (j in i) {
				if (j.item == item) {
					j.item.remove();
					j.item = to;
				}
			}
		}
	}
}
