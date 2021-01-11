package en;

import cherry.soup.EventSignal.EventSignal0;
import en.items.Blueprints.Blueprint;
import h2d.Scene;
import h2d.RenderContext;
import en.player.Player;
import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

@:keep
class Item extends Object {
	public var ent : Entity;
	public var spr : HSprite;
	public var interactive : h2d.Interactive;
	public var cdbEntry : Data.ItemsKind;
	public var amount(default, set) : Int = 1;
	public var amountLabel : TextLabel;
	public var structureUsingEvent = new EventSignal0();

	var displayText : String = "";
	var textLabel : TextLabel;
	var bitmap : Bitmap;

	inline function set_amount(v : Int) {
		if ( v == 0 ) Player.inst.ui.inventory.invGrid.removeItem(this, null);
		amountLabel.label = '${v}';
		return amount = v;
	}

	inline public function isInSlot() : Bool return Std.is(parent, h2d.Interactive);

	inline public function isInCursor() : Bool return Std.is(parent, Scene);

	inline public function isSameTo(item : Item) : Bool return '${item}' == '$this' && item.cdbEntry == cdbEntry;

	public function new(cdbEntry : ItemsKind, ?parent : Object) {
		super(parent);
		this.cdbEntry = cdbEntry;
		if ( spr == null ) {
			spr = new HSprite(Assets.items, this);
			if ( cdbEntry != null ) {
				spr.set(Data.items.get(cdbEntry).atlas_name);
				displayText = Data.items.get(cdbEntry).display_name;
			}
		}

		spr.tile.getTexture().filter = Nearest;
		spr.setCenterRatio();

		amountLabel = new TextLabel('$amount', Assets.fontPixel, this);
		amountLabel.horizontalAlign = Right;
		amountLabel.verticalAlign = Bottom;
		amountLabel.scale(.5);

		amountLabel.paddingLeft = 5;
		amountLabel.paddingTop = 2;

		amountLabel.containerFlow.padding = 2;
		amountLabel.containerFlow.paddingTop = -4;
		amountLabel.containerFlow.paddingBottom = 3;
		amountLabel.containerFlow.paddingLeft = 1;
		// amountLabel.containerFlow.paddingTop  = -2;

		// amountLabel.containerFlow.he = 2;

		interactive = new Interactive(spr.tile.width, spr.tile.height, spr);
		interactive.onOver = function(e : hxd.Event) {
			textLabel = new TextLabel(displayText, Assets.fontPixel, Boot.inst.s2d);
		}

		interactive.onOut = function(e : hxd.Event) {
			textLabel.dispose();
		}

		interactive.onPush = function(e : hxd.Event) {
			var swapHold = () -> {
				// swapping this item with the one player holds
				Player.inst.ui.inventory.belt.deselectCells();
				Player.inst.enableGrids();
				var swapItem = Game.inst.player.holdItem;
				swapItem = (swapItem == this) ? null : swapItem;

				Player.inst.holdItem = this;
				Player.inst.ui.inventory.invGrid.removeItem(this, swapItem);

				Boot.inst.s2d.addChild(this);
				scaleX = scaleY = 2;
			}
			// Picking up the item into the player's holdItem (cursor)
			if ( Player.inst.ui.inventory.sprInv.visible ) {
				textLabel.dispose();
				if ( Player.inst.holdItem != null && isSameTo(Player.inst.holdItem) ) {
					// folding item from cursor with this item
					if ( Player.inst.holdItem.isInCursor() ) {
						if ( amount + Player.inst.holdItem.amount <= Data.items.get(cdbEntry).stack.int() ) {
							amount += Player.inst.holdItem.amount;
							Player.inst.holdItem.dispose();
							Player.inst.holdItem = null;
						}
					} else
						swapHold();
				} else if ( Player.inst.holdItem == null ) swapHold(); else if ( !Player.inst.holdItem.isInCursor() ) {
					Player.inst.ui.inventory.belt.deselectCells();
					Player.inst.enableGrids();
					Player.inst.ui.inventory.invGrid.removeItem(this, null);
					Boot.inst.s2d.addChild(this);
					scaleX = scaleY = 2;
					Player.inst.holdItem = this;
				} else {
					swapHold();
				}
				// if ( Player.inst.holdItem != null && !Player.inst.holdItem.isInCursor() ) {
				// 	Player.inst.holdItem = this;
				// }
			} else if ( isInSlot() ) {
				// Selecting item in the belt if inventory is hidden
				var beltGrid = Player.inst.ui.inventory.invGrid.interGrid[Player.inst.ui.inventory.invGrid.interGrid.length - 1];
				var cout = 1;
				for (i in beltGrid) {
					if ( i.item == this ) Player.inst.ui.inventory.belt.selectCell(cout);
					cout++;
				}
			}
		}
	}

	public function dispose() {
		this.remove();
		spr.remove();
		interactive.remove();
		spr = null;
	}

	override function sync(ctx : RenderContext) {
		amountLabel.paddingLeft = 16 - amountLabel.innerWidth;
		if ( textLabel != null ) {
			textLabel.x = Boot.inst.s2d.mouseX + 20;
			textLabel.y = Boot.inst.s2d.mouseY + 20;
		}
		interactive.width = spr.tile.width;
		interactive.height = spr.tile.height;

		interactive.x = -spr.tile.width / 2;
		interactive.y = -spr.tile.height / 2;

		if ( isInCursor() ) {
			x = Boot.inst.s2d.mouseX + 13 * scaleX;
			y = Boot.inst.s2d.mouseY + 13 * scaleY;
		}
		super.sync(ctx);
	}

	public static function fromCdbEntry(cdbEntry : ItemsKind, ?amount : Int = 1, ?parent : Object) {
		var item : Item = null;
		var entClasses = (CompileTime.getAllClasses(Item));
		for (e in entClasses) {
			if ( Data.items.get(cdbEntry).cat != blueprint ) {
				if ( eregCompTimeClass.match('$e'.toLowerCase())
					&& eregCompTimeClass.matched(1) == Data.items.get(cdbEntry).id.toString() ) {
					item = Type.createInstance(e, [cdbEntry, parent]);
				}
			} else
				item = new Blueprint(cdbEntry, parent);
		}
		item = item == null ? new Item(cdbEntry) : item;
		item.amount = amount;

		return item;
	}
}

class StackExtender {
	static inline public function int(i : Data.Items_stack) {
		return switch i {
			case _1: 1;
			case _4: 4;
			case _16: 16;
			case _64: 64;
		}
	}
}
