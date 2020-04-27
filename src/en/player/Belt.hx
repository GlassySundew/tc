package en.player;

import en.player.Inventory.InventoryGrid;
import h2d.Flow;
import h2d.Object;
import h2d.Font;
import h2d.domkit.Style;

@:uiComp("container")
class BeltCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = 
		<container>
		    <flow>
		      <flow class="beltSlot" public id="beltSlot">
				<flow class="itemContainer" public id="itemContainer" />
				<flow class="absolute" public id="absolute"/>
		        <flow class="hotkeyContainer">
		          <text
		            class="beltSlotNumber"
		            text={Std.string(slotNumber)}
		            font={font}
		          />
		        </flow>
		      </flow>
			</flow>
		</container>;
		// public var item(default, set):Item;
		// inline function set_item(v:Item) {
		// 	trace(item);
		// 	if (v != null) {
		// 		v.spr.scaleX = v.spr.scaleY = 3;
		// 		this.itemContainer.addChild(v.spr);
		// 	} else if (item != null) {
		// 		trace(this.itemContainer, item);
		// 		this.itemContainer.removeChild(item.spr);
		// 	}
		// 	return item = v;
		// }
		public function new(?font:Font, ?slotNumber:Int, ?parent) {
			super(parent);

			initComponent();
			// initComponent();
		}
}

class Belt extends dn.Process {
	var centerFlow:Flow;
	var style:Style;
	public var invGrid:InventoryGrid;
	public static var beltSlots:Array<BeltCont> = [];

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
		for(i in 0...beltSlots.length){
			beltSlots[i].absolute.addChild(invGrid.interGrid[i][0].inter);
		}
		var iten = new en.items.GraviTool(0, 0);
		
		invGrid.interGrid[1][0].item = iten;
	}

	// public function removeItem(item:Item) {
	// 	var n:Null<Int> = null;
	// 	for (slot in beltSlots) {
	// 		if (slot.getChildIndex(item.spr) != n) {
	// 			slot.item = null;
	// 		}
	// 	}
	// }

	override function onResize() {
		centerFlow.minWidth = Boot.inst.s2d.width;
		centerFlow.minHeight = Boot.inst.s2d.height;

		// centerFlow.x = Boot.inst.s2d.width / 2;
		// centerFlow.y = Boot.inst.s2d.height - 100;
	}
}
