package en.player;

import h3d.Vector;
import en.player.Inventory.InventoryGrid;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("container")
class BeltCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<container>
		      <flow class="beltSlot" public id="beltSlot">
				<flow class="itemContainer" public id="itemContainer" />
				<flow class="absolute" public id="absolute"/>
		        <flow class="hotkeyContainer" >
		          <text
					class="beltSlotNumber"
					public id="beltSlotNumber"
		            text={Std.string(slotNumber)}
		            font={font}
		          />
		        </flow>
		      </flow>
		</container>;
		public function new(?font:Font, ?slotNumber:Int, ?parent) {
			super(parent);
			initComponent();
		}
}
class Belt extends dn.Process {
	var player(get, null):Player;

	inline function get_player()
		return Player.inst;

	var centerFlow:Flow;
	var style:Style;

	public var invGrid:InventoryGrid;

	public static var beltSlots:Array<BeltCont> = [];

	public var selectedCell:BeltCont;

	public function new() {
		super();
		centerFlow = new h2d.Flow();
		Main.inst.root.add(centerFlow, Const.DP_UI);
		Main.inst.root.under(centerFlow);
		onResize();

		style = new h2d.domkit.Style();
		style.load(hxd.Res.domkit.belt);
		for (i in 1...5) {
			beltSlots.push(new BeltCont(Assets.fontPixel, i, centerFlow));
			style.addObject(beltSlots[i - 1]);
		}

		invGrid = new InventoryGrid(0, 0, beltSlots[0].beltSlot.minWidth, beltSlots[0].beltSlot.minHeight, beltSlots.length, 1, 20, 0, Boot.inst.s2d);
		invGrid.enableGrid();
		for (i in 0...beltSlots.length) {
			beltSlots[i].absolute.addChild(invGrid.interGrid[i][0].inter);
		}
		
		var iten = new en.items.GraviTool();
		invGrid.interGrid[2][0].item = iten;
	}

	public function selectCell(number:Int = 1) {
		if (player.cursorItem == null) {
			deselectCells();
			var cell = beltSlots[number - 1];
			cell.beltSlot.backgroundTile = h2d.Tile.fromColor(0x6bace6, 1, 1, .58);
			cell.beltSlotNumber.color = Color.intToVector(0xbabac8);
			cell.paddingBottom = 10;

			// if (player.holdItem == null)
			// 	player.holdItem = cell.
		}
	}

	public function deselectCells() {
		for (i in beltSlots) {
			style.addObject(i);
			i.paddingBottom = 0;
		}
	}

	override function onResize() {
		centerFlow.minWidth = Boot.inst.s2d.width;
		centerFlow.minHeight = Boot.inst.s2d.height;

		// centerFlow.x = Boot.inst.s2d.width / 2;
		// centerFlow.y = Boot.inst.s2d.height - 100;
	}
}
