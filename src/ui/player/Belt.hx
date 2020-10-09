package ui.player;

import h2d.RenderContext;
import en.player.Player;
import h3d.Vector;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

class Belt extends Object {
	var player(get, null): Player;

	inline function get_player() return Player.inst;

	var centerFlow: Flow;
	var style: Style;

	var beltSlots: Array<BeltCont> = [];

	public var selectedCell: BeltCont;

	public function new(parent: Inventory) {
		super(parent);
		centerFlow = new h2d.Flow(this);
		// Main.inst.root.add(centerFlow, Const.DP_UI);
		// Main.inst.root.under(centerFlow);

		style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.belt);

		// for (i in 1...5) {
		// 	beltSlots.push(new BeltCont(Assets.fontPixel, i, centerFlow));
		// 	style.addObject(beltSlots[i - 1]);
		// }

		// invGrid = new InventoryGrid(0, 0, beltSlots[0].beltSlot.outerWidth, beltSlots[0].beltSlot.outerHeight, beltSlots.length, 1, 0, 0, this);
		// for (i in 0...beltSlots.length) {
		// 	beltSlots[i].itemContainer.addChild(invGrid.interGrid[0][i].inter);
		// }
		// parent.invGrid.interGrid[0][0].inter.width =
		var cout = 1;
		for (i in parent.invGrid.interGrid) {
			for (j in i) {
				if (j.parent == null) {
					beltSlots.push(new BeltCont(Assets.fontPixel, cout, centerFlow));
					style.addObject(beltSlots[cout - 1]);
					beltSlots[cout - 1].itemContainer.addChild(j.inter);
					j.inter.width = beltSlots[0].beltSlot.innerWidth;
					j.inter.height = beltSlots[0].beltSlot.innerHeight;
					cout++;
				}
			}
		}

		// var iten = new en.items.GraviTool();
		// invGrid.interGrid[2][0].item = iten;
		deselectCells();
		// invGrid.disableGrid();
	}

	public function selectCell(number: Int = 1) {
		deselectCells();
		var cell = beltSlots[number - 1];
		cell.beltSlot.backgroundTile = h2d.Tile.fromColor(0x6bace6, 1, 1, .58);
		cell.beltSlotNumber.color = Color.intToVector(0xbabac8);
		cell.paddingBottom = 10;

		if (player.holdItem == null && !player.ui.inventory.sprInv.visible)
			player.holdItem = player.ui.inventory.invGrid.interGrid[player.ui.inventory.invGrid.interGrid.length
			- 1][number - 1].item;
	}

	public function deselectCells() {
		for (i in beltSlots) {
			style.addObject(i);
			i.paddingBottom = 0;
		}
	}

	override function sync(ctx: RenderContext) {
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
