package ui.player;

import en.items.Scepter;
import en.player.Player;
import h2d.RenderContext;
import h2d.Object;
import en.items.GraviTool;
import ui.player.Belt;
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

/**
	Формочки для Player, визуализация InventoryGrid
**/
class Inventory extends Object {
	public var belt:Belt;
	// public var items:Array<Array<Item>> = [[]];
	public var invGrid:InventoryGrid;

	var invGrid0x = 0;
	var invGrid0y = 0;

	var ca:dn.heaps.Controller.ControllerAccess;

	public var base:Bitmap;

	public function new(?parent:Object) {
		super(parent);
		// this.scaleX = this.scaleY = 0.5;
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

		base = new h2d.Bitmap(sprInv.tile, this);
		base.visible = !base.visible;

		var textLabel = new ui.TextLabel("Inventory", Assets.fontPixel, base);
		textLabel.minWidth = Std.int(base.tile.width * Const.SCALE);
		textLabel.scale(.5);
		// textLabel.horizontalAlign = Middle;
		textLabel.paddingTop = 6 + textLabel.outerHeight >> 1 ; // пиздец

		belt = new Belt(this);
		invGrid = new InventoryGrid(invGrid0x, invGrid0y, 20, 20, 4, 4, 4, 4, base);
		// invGrid.giveItem(new en.items.Scepter(0, 0));
		// items[0].push(new en.items.Ore(invGrid0x, invGrid0y, Iron, base));
	}

	function recenter() {
		base.x = Std.int((getS2dScaledWid() - base.tile.width) / 2 );
		base.y = Std.int((getS2dScaledHei() - base.tile.height) / 2);
	}

	public function toggleVisible() {
		base.visible = !base.visible;
		recenter();
	}
}
