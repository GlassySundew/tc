package en.player;

import en.items.GraviTool;
import ui.Belt;
import hxd.Event;
import h2d.Tile;
import h3d.mat.Texture;
import hxd.res.Resource;
import domkit.Macros;
import h2d.domkit.Style;
import h2d.Flow;
import haxe.io.Bytes;
import h2d.Bitmap;
import h2d.ScaleGrid;

class InventoryCell {
	public var item(default, set):Item;
	public var inter:h2d.Interactive;

	inline function set_item(v:Item) {
		if (v != null) {
			// v.spr.scaleX = v.spr.scaleY = 1;
			v.spr.setCenterRatio();
			v.spr.scaleX = v.spr.scaleY = ((inter.parent == Std.downcast(inter.parent, ScaleGrid)) ? 1 : 3);
			inter.addChild(v.spr);
			v.x = inter.width / 2;
			v.y = inter.height / 2;
		}

		return item = v;
	}

	public function new(width:Int, height:Int, ?parent:h2d.Object) {
		inter = new h2d.Interactive(width, height, parent);
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

class InventoryGrid {
	public static var ALL:Array<InventoryGrid> = [];

	var player(get, never):Player;

	inline function get_player()
		return Player.inst;

	public var interGrid:Array<Array<InventoryCell>>;

	public function new(x:Int, y:Int, width:Int, height:Int, horCells:Int, verCells:Int, xGap:Int, yGap:Int, ?parent:h2d.Object) {
		ALL.push(this);
		interGrid = [for (i in 0...verCells) []];
		for (j in 0...horCells) {
			interGrid[j] = [];
			for (i in 0...verCells) {
				var tempInter = new InventoryCell(width, height, parent);
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
					j.item.spr.remove();
					j.item = to;
				}
			}
		}
	}
}

class Inventory extends dn.Process {
	public var belt:Belt;
	// public var items:Array<Array<Item>> = [[]];
	public var invGrid:InventoryGrid;

	var invGrid0x = 0;
	var invGrid0y = 0;

	var ca:dn.heaps.Controller.ControllerAccess;

	public var base:ScaleGrid;

	public function new() {
		super(Main.inst);

		ca = Main.inst.controller.createAccess("inventory");

		// parsing pure red color (0x0ffff0000) as a top left point of grid start
		var sprInv = new HSprite(Assets.ui);
		sprInv.set("inventory");
		var bmpTex = sprInv.tile.getTexture().capturePixels();

		var loopBreak = false;
		for (i in 0...bmpTex.height) {
			for (j in 0...bmpTex.width)
				if (bmpTex.getPixel(j, i) == 0xffff0000) {
					invGrid0x = j;
					invGrid0y = i;
					// replacing red point with a background pixel from j-1, i-1
					bmpTex.setPixel(j, i, bmpTex.getPixel(j - 1, i - 1));
					sprInv.tile.switchTexture(Tile.fromTexture(Texture.fromPixels(bmpTex)));
					loopBreak = true;
					break;
				}
			loopBreak ? break:0;
		}

		base = new h2d.ScaleGrid(sprInv.tile, 0, 0, Boot.inst.s2d);
		base.visible = !base.visible;
		base.setScale(Const.UI_SCALE);
		new ui.TextLabel(Middle, "Inventory", Assets.fontPixel, 1, Std.int(base.tile.width * 2), base);
		// items[0].push(new en.items.Ore(invGrid0x, invGrid0y, Iron, base));
		belt = new Belt();

		invGrid = new InventoryGrid(invGrid0x, invGrid0y, 20, 20, 4, 4, 4, 4, base);
		// invGrid.giveItem(new en.items.GraviTool(0, 0));

		onResize();
	}

	function recenter() {
		base.x = (Boot.inst.s2d.width >> 1) - base.width * base.scaleX / 2;
		base.y = (Boot.inst.s2d.height >> 1) - base.height * base.scaleY / 2;
	}

	public function toggleVisible() {
		base.visible = !base.visible;
		recenter();
	}

	override function update() {
		super.update();
	}

	override function postUpdate() {
		super.postUpdate();
		// for (i in 0...invGrid.interGrid.length)
		// 	for (j in 0...invGrid.interGrid[i].length)
		// 		if (invGrid.interGrid[i][j] == invGrid.getFreeSlot())
		// 			trace(i, j);

		// for (i in invGrid.interGrid)
		// 	for (j in i)
		// 		j.inter.visible = (Game.inst.player.holdItem != null);
	}

	override function onResize() {
		super.onResize();
		belt.centerFlow.minWidth = Boot.inst.s2d.width;
		belt.centerFlow.minHeight = Boot.inst.s2d.height;
	}
}
