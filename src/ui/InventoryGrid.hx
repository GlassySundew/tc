package ui;

import haxe.Constraints.Function;
import h3d.scene.Object;
import h2d.ScaleGrid;
import hxd.Event;
import en.player.Player;

class InventoryCell extends h2d.Object {
	public var item(default, set): Item;
	public var inter: h2d.Interactive;

	inline function set_item(v: Item) {
		if (v != null) {
			inter.addChild(v);
			v.x = inter.width / 2;
			v.y = inter.height / 2;
			v.setScale(1);
		}

		return item = v;
	}

	public function new(?width: Int = 0, ?height: Int = 0, ?parent: h2d.Object) {
		super(parent);
		inter = new h2d.Interactive(width, height, this);
		// inter.visible = false;
		inter.cursor = Default;
		inter.onPush = function(e: Event) {
			if (Player.inst.holdItem != null && Player.inst.holdItem.isInCursor() && item == null) {
				item = Game.inst.player.holdItem;
				Game.inst.player.holdItem = null;
				// Когда кладём предмет в слот, все курсоры сеток должны быть выключены
				Player.inst.disableGrids();
			}
		}
	}

	public override function onRemove() {
		super.onRemove();
	}
}

class CellGrid2D {
	var player(get, never): Player;

	inline function get_player() return Player.inst;

	public var itemCout(get, never): Int;

	function get_itemCout() {
		var cout = 0;
		for (i in grid)
			for (j in i)
				if (j.item != null) cout++;
		return cout;
	}

	public var grid: Array<Array<InventoryCell>>;

	public function new(width: Int, height: Int, ?cellWidth: Int = 0, ?cellHeight: Int = 0, ?parent: h2d.Object) {
		grid = [
			for (_ in 0...height) [for (_ in 0...width) new InventoryCell(cellWidth, cellHeight, parent)]
		];
	}

	public function disableGrid() {
		for (i in grid)
			for (j in i) {
				if (j.item == null) j.inter.cursor = Default;
			}
	}

	public function enableGrid() {
		for (i in grid)
			for (j in i) {
				if (j.item == null) j.inter.cursor = Button;
			}
	}

	public function getFreeSlot(): InventoryCell {
		for (i in grid)
			for (j in i)
				if (j.item == null) return j;

		return null;
	}

	public function giveItem(item: Item) {
		var slot = getFreeSlot();
		if (slot != null) slot.item = item;
		return slot;
	}

	public function removeItem(item: Item, ?to: Item = null): Item {
		for (i in grid) {
			for (j in i) {
				if (j.item == item) {
					j.item.remove();
					j.item = to;
					return j.item;
				}
			}
		}
		return null;
	}

	public function findSlot(item: Item): InventoryCell {
		for (i in grid)
			for (j in i)
				if (j.item == item) return j;
		return null;
	}

	@:allow(Interactive) function dispose() {}
}
/**	h2d.Interactive формочки для инвентарной сетки **/
class InventoryGrid extends h2d.Object {
	public var interGrid: Array<Array<InventoryCell>>;

	var cellGrid: CellGrid2D;

	public var disableGrid: Void->Void;
	public var enableGrid: Void->Void;
	public var getFreeSlot: Void->InventoryCell;
	public var giveItem: Item->InventoryCell;
	public var removeItem: Item->Item->Item;
	public var findSlot: Item->InventoryCell;

	public function new(x: Int, y: Int, width: Int, height: Int, horCellsAmount: Int, verCellsAmount: Int, xGap: Int, yGap: Int, ?parent: h2d.Object) {
		super(parent);
		cellGrid = new CellGrid2D(horCellsAmount, verCellsAmount, width, height, this);
		interGrid = cellGrid.grid;

		disableGrid = cellGrid.disableGrid.bind();
		enableGrid = cellGrid.enableGrid.bind();
		getFreeSlot = cellGrid.getFreeSlot.bind();
		giveItem = cellGrid.giveItem.bind();
		findSlot = cellGrid.findSlot.bind();
		removeItem = (item: Item, ?to: Item = null) -> {
			cellGrid.removeItem(item, to);
		};

		for (j in 0...interGrid.length) {
			for (i in 0...interGrid[j].length) {
				var tempInter = interGrid[j][i];
				tempInter.inter.x = x + i * (width + xGap);
				tempInter.inter.y = y + j * (height + yGap);
			}
		}
	}

	public function dispose() {
		for (i in interGrid)
			for (j in i) {
				j.inter.remove();
			}
	}
}
