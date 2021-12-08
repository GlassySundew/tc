package en;

import ch2.ui.EventInteractive;
import cherry.soup.EventSignal.EventSignal0;
import en.player.Player;
import en.structures.Chest;
import h2d.Bitmap;
import h2d.Object;
import h2d.RenderContext;
import h2d.Scene;
import hxd.Key;
import ui.domkit.TextLabelComp;

@:keep class Item extends Object {
	public var ent : Entity;
	public var spr : HSprite;
	public var interactive : EventInteractive;
	public var cdbEntry : Data.ItemsKind;
	public var amount(default, set) : Int = 1;
	public var amountLabel : TextLabelComp;

	var over : Bool = false;

	public var onStructureUse = new EventSignal0();
	public var onPlayerHold = new EventSignal0();
	public var onPlayerRemove = new EventSignal0();

	public var containerEntity : Entity;

	public var isDisposed : Bool;

	var displayText : String = "";
	var textLabel : TextLabelComp;
	var bitmap : Bitmap;
	var ca : dn.heaps.Controller.ControllerAccess;

	inline function set_amount( v : Int ) {
		if ( v <= 0 ) dispose();
		amountLabel.label = '${v}';
		return amount = v;
	}

	inline public function isInSlot() : Bool return Std.isOfType(parent, h2d.Interactive);

	inline public function isInCursor() : Bool return Std.isOfType(parent, Scene);

	public function isInBelt() : Bool {
		if ( Player.inst != null ) {
			for ( i in Player.inst.cellGrid.grid[Player.inst.cellGrid.grid.length - 1] ) if ( i.item == this ) return true;
			return false;
		} else
			return false;
	}

	inline public function isSameTo( item : Item ) : Bool return '${item}' == '$this' && item.cdbEntry == cdbEntry;

	public function new( cdbEntry : Data.ItemsKind, ?parent : Object ) {
		super(parent);
		ca = Main.inst.controller.createAccess("chest");

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

		amountLabel = new TextLabelComp('$amount', Assets.fontPixel, this);
		amountLabel.horizontalAlign = Right;
		amountLabel.verticalAlign = Bottom;
		amountLabel.scale(.5);

		amountLabel.containerFlow.paddingTop = -2;
		amountLabel.containerFlow.paddingLeft = -1;

		interactive = new EventInteractive(spr.tile.width, spr.tile.height, spr);
		interactive.enableRightButton = true;

		interactive.onOver = function ( e : hxd.Event ) {
			over = true;
			textLabel = new TextLabelComp(displayText, Assets.fontPixel, Boot.inst.s2d);
		}

		interactive.onOut = function ( e : hxd.Event ) {
			over = false;
			textLabel.dispose();
		}

		interactive.onFocusEvent.add(function ( e : hxd.Event ) {});

		interactive.onPush = ( e ) -> {
			over = false;
			textLabel.dispose();
		}

		interactive.propagateEvents = true;
		
		isDisposed = false;
	}

	override function onRemove() {
		super.onRemove();
		// isDisposed = true;
	}

	inline public function dispose() {
		if ( Player.inst != null && this == Player.inst.holdItem ) Player.inst.holdItem = null;

		isDisposed = true;
		this.remove();
		spr.remove();
		interactive.remove();
		spr = null;
		textLabel.remove();
		amountLabel.remove();

		for ( e in Entity.ALL ) if ( e.cellGrid != null ) e.cellGrid.grid.findAndReplaceItem(this);
	}

	override function sync( ctx : RenderContext ) {
		if ( spr != null ) {
			if ( textLabel != null ) {
				textLabel.x = Boot.inst.s2d.mouseX + 30;
				textLabel.y = Boot.inst.s2d.mouseY + 30;
			}
			interactive.width = spr.tile.width;
			interactive.height = spr.tile.height;

			interactive.x = -spr.tile.width / 2;
			interactive.y = -spr.tile.height / 2;

			amountLabel.x = 7 - amountLabel.containerFlow.innerWidth / 2;

			if ( over ) {
				if ( ca.yPressed() ) {
					if ( !isDisposed ) if ( Key.isDown(Key.CTRL) ) {
						// dropping whole stack
						Player.inst.dropItem(Item.fromCdbEntry(cdbEntry, amount), Player.inst.angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
						amount = 0;
					} else {
						// dropping 1 item
						amount--;
						Player.inst.dropItem(Item.fromCdbEntry(cdbEntry, 1), Player.inst.angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
					}
				}
			}
		}
		super.sync(ctx);
	}

	public static function fromCdbEntry( cdbEntry : Data.ItemsKind, ?amount : Int = 1, ?parent : Object ) {
		var item : Item = null;

		var entClasses = CompileTime.getAllClasses(Item);
		for ( e in entClasses ) {
			if ( eregCompTimeClass.match('$e'.toLowerCase())
				&& eregCompTimeClass.matched(1) == Data.items.get(cdbEntry).id.toString().toLowerCase() ) {
				item = Type.createInstance(e, [cdbEntry, parent]);
			}
		}
		// if(item == null && Data.cdbEntry)
		item = item == null ? new Item(cdbEntry) : item;
		item.amount = amount;

		return item;
	}
}

class StackExtender {
	static inline public function int( i : Data.Items_stack ) {
		return switch i {
			case _1: 1;
			case _4: 4;
			case _16: 16;
			case _64: 64;
		}
	}
}
