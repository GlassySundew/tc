package ui.player;

import ui.InventoryGrid.InventoryCellFlow;
import en.player.Player;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.domkit.Style;
import ui.InventoryGrid.InventoryCell;
import ui.InventoryGrid.UICellGrid;

class Belt extends Object {
	var centerFlow : Flow;
	var style : Style;

	public var beltSlots : Array<BeltCont> = [];

	public var selectedCell : BeltCont;
	public var selectedCellNumber : Int = 0;
	public var grid : Array<InventoryCellFlow>;

	public function new( cellGrid : Array<InventoryCellFlow>, ?parent : h2d.Object ) {
		super(parent);

		grid = cellGrid;

		for ( i in cellGrid ) i.cell.containerType = Belt;

		centerFlow = new h2d.Flow(this);

		style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.belt);

		var cout = 1;
		for ( cellFlow in grid ) {
			var beltCont = new BeltCont(Assets.fontPixel, cout, centerFlow);
			beltSlots.push(beltCont);
			style.addObject(beltCont);
			beltCont.itemContainer.addChild(cellFlow);
			cellFlow.inter.width = beltSlots[0].innerWidth;
			cellFlow.inter.height = beltSlots[0].innerHeight;
			cout++;
		}

		// var iten = new en.items.GraviTool();
		// cellGrid.interGrid[2][0].item = iten;

		deselectCells();
	}

	public function selectCell( number : Int = 1 ) {
		deselectCells();
		
		if ( Player.inst.holdItem == null || Player.inst.holdItem.itemPresense != Cursor ) {
			selectedCellNumber = number;
			var cell = beltSlots[number - 1];

			// cell.backgroundColor = Color.rgbaToInt({
			// 	r : 107,
			// 	g : 172,
			// 	b : 230,
			// 	a : 212
			// });

			cell.dom.active = true;
			cell.backgroundFlow.dom.active = true;

			Player.inst.holdItem = Player.inst.ui.beltLayer[number - 1].cell.item;

			style.addObject(cell);
		}
	}

	public function deselectCells() {
		for ( cell in beltSlots ) {
			//   background: #494e55;

			cell.dom.active = false;
			cell.backgroundFlow.dom.active = false;

			// i.beltSlotNumber.dom.active = false;
			// i.backgroundColor = Color.rgbaToInt({
			// 	r : 73,
			// 	g : 78,
			// 	b : 85,
			// 	a : 200
			// });
			style.addObject(cell);
		}
	}

	override function sync( ctx : RenderContext ) {
		centerFlow.minWidth = Std.int(wScaled);
		centerFlow.minHeight = Std.int(hScaled);
		super.sync(ctx);
	}

	override function onRemove() {
		super.onRemove();
		for ( i in beltSlots ) {
			i.remove();
			style.removeObject(i);
		}
	}
}
