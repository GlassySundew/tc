package en;

import ui.s2d.EventInteractive;
import hxd.Res;
import en.structures.Chest;
import ui.InventoryGrid.InventoryCell;
import hxd.Key;
import ui.player.Inventory;
import cherry.soup.EventSignal.EventSignal0;
import en.items.Blueprint;
import h2d.Scene;
import h2d.RenderContext;
import en.player.Player;
import ui.TextLabel;
import h2d.Bitmap;
import h2d.Object;
import h2d.Interactive;

@:keep class Item extends Object {
	public var ent : Entity;
	public var spr : HSprite;
	public var interactive : EventInteractive;
	public var cdbEntry : Data.ItemsKind;
	public var amount(default, set) : Int = 1;
	public var amountLabel : TextLabel;

	var over : Bool = false;

	public var onStructureUse = new EventSignal0();
	public var onPlayerHold = new EventSignal0();
	public var onPlayerRemove = new EventSignal0();

	public var containerEntity : Entity;

	public var isDisposed : Bool;

	var displayText : String = "";
	var textLabel : TextLabel;
	var bitmap : Bitmap;
	var ca : dn.heaps.Controller.ControllerAccess;

	inline function set_amount(v : Int) {
		if ( v <= 0 ) dispose();
		amountLabel.label = '${v}';
		return amount = v;
	}

	inline public function isInSlot() : Bool return Std.isOfType(parent, h2d.Interactive);

	inline public function isInCursor() : Bool return Std.isOfType(parent, Scene);

	public function isInBelt() : Bool {
		if ( Player.inst != null ) {
			for (i in Player.inst.invGrid.grid[Player.inst.invGrid.grid.length - 1]) if ( i.item == this ) return true;
			return false;
		} else
			return false;
	}

	inline public function isSameTo(item : Item) : Bool return '${item}' == '$this' && item.cdbEntry == cdbEntry;

	public function new(cdbEntry : ItemsKind, ?parent : Object) {
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

		interactive = new EventInteractive(spr.tile.width, spr.tile.height, spr);
		interactive.enableRightButton = true;

		interactive.onOver = function(e : hxd.Event) {
			over = true;
			textLabel = new TextLabel(displayText, Assets.fontPixel, Boot.inst.s2d);
		}

		interactive.onOut = function(e : hxd.Event) {
			over = false;
			textLabel.dispose();
		}

		interactive.onFocusEvent.add(function(e : hxd.Event) {});

		interactive.onPush = function(e : hxd.Event) {
			if ( e.button == 0 ) {
				// Левая кнопка мыши
				var swapHold = () -> {
					// swapping this item with the one player holds
					Player.inst.ui.belt.deselectCells();
					for (i in Inventory.ALL) i.invGrid.enableGrid();

					var swapItem = Game.inst.player.holdItem;
					swapItem = (swapItem == this) ? null : swapItem;

					for (i in Inventory.ALL) i.invGrid.findAndReplaceItem(this, swapItem);
					Player.inst.holdItem = this;
				}
				// Быстрый перенос предмета через shift
				if ( Key.isDown(Key.SHIFT) ) {
					// Если предмет в поясе, то перенести в основной инвентарь
					if ( isInBelt() ) {
						// Если предмет выбран на поясе, то очистить выбор
						if ( Player.inst.holdItem != null && Player.inst.holdItem.isInBelt() ) {
							Player.inst.ui.belt.deselectCells();
							Player.inst.holdItem = null;
						}
						var freeSlot = Player.inst.invGrid.getFreeSlot();
						if ( freeSlot != null ) {
							textLabel.dispose();
							Player.inst.invGrid.findAndReplaceItem(this);
							Player.inst.invGrid.findAndReplaceItem(freeSlot.item, this);
						}
					} else {
						// Предмет был кликнут в какой-то инвентарной сетке
						if ( containerEntity.isOfType(Chest) ) {
							// Если данный предмет в сундуке - то перенести его в инвентарь игрока

							var freeSlot = Player.inst.invGrid.getFreeSlot();
							if ( freeSlot != null ) {
								textLabel.dispose();
								containerEntity = Player.inst;

								for (i in Inventory.ALL) if ( i.invGrid != Player.inst.invGrid
									&& i.invGrid.findAndReplaceItem(this) != null ) break;
								Player.inst.invGrid.findAndReplaceItem(freeSlot.item, this);
							}
						} else if ( containerEntity.isOfType(Player) ) {
							// Предмет был кликнут в инвентарной сетке игрока
							var itemWasMoved = false;
							var giveItemToFirstVisibleChest = () -> {
								for (i in Inventory.ALL) {
									if ( i.containmentEntity.isOfType(Chest) && i.win.visible && i.win.parent != null ) {
										// Перемещаем из игрока в тот сундук, с которым в прошлый раз взаимодействовали
										var freeSlot = i.invGrid.getFreeSlot();
										if ( freeSlot != null ) {
											containerEntity = i.containmentEntity;
											textLabel.dispose();
											Player.inst.invGrid.findAndReplaceItem(this);
											i.invGrid.findAndReplaceItem(freeSlot.item, this);
											itemWasMoved = true;
										}
										return;
									}
								}
							}
							giveItemToFirstVisibleChest();

							// Если не открыто ни одного окна с сундуком - то переместить предмет в пояс
							if ( !itemWasMoved ) {
								var freeSlot = Player.inst.ui.belt.getFreeSlot();
								if ( freeSlot != null ) {
									textLabel.dispose();
									Player.inst.invGrid.findAndReplaceItem(this);
									Player.inst.ui.belt.findAndReplaceItem(freeSlot.item, this);
								}
							}
						}
					}
				} else {
					// Picking up the item into the player's holdItem (cursor)
					if ( isInBelt() && !Player.inst.ui.inventory.win.visible ) {
						// Selecting item in the belt if inventory is hidden
						var beltGrid = Player.inst.invGrid.grid[Player.inst.invGrid.grid.length - 1];
						var cout = 1;
						for (i in beltGrid) {
							if ( i.item == this ) Player.inst.ui.belt.selectCell(cout);
							cout++;
						}
					} else {
						textLabel.dispose();
						if ( Player.inst.holdItem != null && !Player.inst.holdItem.isDisposed && isSameTo(Player.inst.holdItem)
							&& !Player.inst.holdItem.isInBelt() ) {
							// folding item from cursor with this item
							if ( Player.inst.holdItem.isInCursor() ) {
								if ( amount + Player.inst.holdItem.amount <= Data.items.get(cdbEntry).stack.int() ) {
									amount += Player.inst.holdItem.amount;
									Player.inst.holdItem.dispose();
									Player.inst.holdItem = null;
								} else
									swapHold();
							} else
								swapHold();
						} else if ( Player.inst.holdItem != null && Player.inst.holdItem.isInBelt() ) {
							Player.inst.ui.belt.deselectCells();
							Player.inst.holdItem = null;
							swapHold();
						} else {
							swapHold();
						}
					}
				}
			} else {
				// Правая кнопка мыши
				if ( Player.inst.holdItem == null || (Player.inst.holdItem != null && Player.inst.holdItem.isInBelt()) ) {
					Player.inst.ui.belt.deselectCells();
					Player.inst.holdItem = Item.fromCdbEntry(cdbEntry, Math.ceil(amount - amount / 2));
					amount = Std.int(amount / 2);
				}
			}
		}
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

		for (i in Inventory.ALL) i.invGrid.findAndReplaceItem(this);
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);
		if ( spr != null ) {
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
				visible = !Game.inst.isPaused();

				x = Boot.inst.s2d.mouseX + 13 * scaleX;
				y = Boot.inst.s2d.mouseY + 13 * scaleY;
			}

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
	}

	public static function fromCdbEntry(cdbEntry : ItemsKind, ?amount : Int = 1, ?parent : Object) {
		var item : Item = null;

		var entClasses = (CompileTime.getAllClasses(Item));
		for (e in entClasses) {
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
	static inline public function int(i : Data.Items_stack) {
		return switch i {
			case _1: 1;
			case _4: 4;
			case _16: 16;
			case _64: 64;
		}
	}
}
