package ui.player;

import ui.InventoryGrid.InventoryCell;
import h2d.RenderContext;
import en.player.Player;
import h3d.Vector;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

class Belt extends Object {
	var player(get, null) : Player;

	inline function get_player() return Player.inst;

	var centerFlow : Flow;
	var style : Style;

	var beltSlots : Array<BeltCont> = [];

	public var selectedCell : BeltCont;
	public var invGrid : Array<InventoryCell>;

	public function new(invGrid : Array<InventoryCell>, ?parent : h2d.Object) {
		super(parent);
		this.invGrid = invGrid;
		centerFlow = new h2d.Flow(this);

		style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.belt);

		var cout = 1;
		for (i in invGrid) {
			var beltCont = new BeltCont(Assets.fontPixel, cout, centerFlow);
			beltSlots.push(beltCont);
			style.addObject(beltCont);
			beltCont.itemContainer.addChild(i.inter);
			i.inter.width = beltSlots[0].beltSlot.innerWidth;
			i.inter.height = beltSlots[0].beltSlot.innerHeight;
			cout++;
		}

		// var iten = new en.items.GraviTool();
		// invGrid.interGrid[2][0].item = iten;
		deselectCells();
	}

	public function findAndReplaceItem(item : en.Item, ?to : en.Item = null) : en.Item {
		for (j in invGrid) if ( j.item == item ) {
			j.item.remove();
			j.item = to;
			return j.item;
		}
		return null;
	}

	public function getFreeSlot() : InventoryCell {
		for (i in invGrid) if ( i.item == null || i.item.isDisposed ) return i;
		return null;
	}

	public function selectCell(number : Int = 1) {
		deselectCells();
		if ( player.holdItem == null || !player.holdItem.isInCursor() ) {
			var cell = beltSlots[number - 1];
			cell.beltSlot.backgroundTile = h2d.Tile.fromColor(0x6bace6, 1, 1, .58);
			cell.beltSlotNumber.color = Color.intToVector(0xbabac8);
			cell.paddingBottom = 10;

			player.holdItem = player.invGrid.grid[player.invGrid.grid.length - 1][number - 1].item;
		}
	}

	public function deselectCells() {
		for (i in beltSlots) {
			style.addObject(i);
			i.paddingBottom = 0;
		}
	}

	override function sync(ctx : RenderContext) {
		centerFlow.minWidth = Std.int(getS2dScaledWid());
		centerFlow.minHeight = Std.int(getS2dScaledHei());
		super.sync(ctx);
	}

	override function onRemove() {
		super.onRemove();
		for (i in beltSlots) {
			i.remove();
			style.removeObject(i);
		}
	}
}
