package ui;

import hxbit.NetworkSerializable;
import ch2.ui.EventInteractive;
import en.Entity;
import en.Item;
import en.player.Player;
import en.structures.Chest;
import h2d.Flow;
import hxbit.Serializable;
import hxd.Event;
import hxd.Key;

/**
	логический держатель сетки для Item
**/
class InventoryGrid implements Serializable {

	@:s public var grid : Array<Array<InventoryCell>>;
	@:s public var width : Int;
	@:s public var height : Int;

	public function new( width : Int, height : Int, ?preparedGrid : Array<Array<InventoryCell>>, ?containmentEntity : Entity ) {
		this.width = width;
		this.height = height;

		grid = preparedGrid != null ? preparedGrid : [
			for ( _ in 0...height ) [
				for ( _ in 0...width ) new InventoryCell(containmentEntity)
			]
		];
	}

	public function getFreeSlot( ?ignoreSlot : InventoryCell ) : InventoryCell {
		for ( i in grid ) for ( j in i )
			if ( (ignoreSlot == null || ignoreSlot != j)
				&& (j.item == null || j.item.isDisposed) )
				return j;
		return null;
	}

	public function findItemKind( kind : Data.Item, amount : Int, except : Array<InventoryCell> ) {
		function isChecked( cell : InventoryCell ) {
			for ( i in except ) if ( cell == i ) return true;
			return false;
		}
		for ( i in grid ) for ( j in i ) if ( j.item != null
			&& !isChecked(j)
			&& Data.item.get(j.item.cdbEntry) == kind
			&& j.item.amount >= amount ) return j;
		return null;
	}

	/**
		@param ignoreFull if true, will return same item even if they are full
	**/
	public function findSameItem( item : Item, ?ignoreSlot : InventoryCell, ?ignoreFull : Bool = true ) : InventoryCell {

		for ( i in grid ) for ( j in i )
			if ( (ignoreSlot == null || ignoreSlot != j)
				&& j.item != null
				&& !j.item.isDisposed
				&& j.item.isSameTo(item)
				&& (j.item.amount < Data.item.get(item.cdbEntry).stack.int() || !ignoreFull) )
				return j;
		return null;
	}

	/**
		@param doStack if false, will ignore same items below maximum capacity and will not stack with them 
		@param sourceSlot if specified, will not put item into it
	**/
	public function giveItem(
		item : en.Item,
		?ignoreSlot : InventoryCell,
		?ignoreFull : Bool = true,
		?doStack : Bool = true ) : InventoryCell {

		// Поиск Item в сетке, amount которого меньше или не равен stack из cdbEntry, и добавление к нему
		var slot = findSameItem(item, ignoreSlot, ignoreFull);

		var splitAndFill : Void -> InventoryCell = () -> {
			do {
				if ( slot.item == null || slot.item.isDisposed ) {
					// Пустая ячейка
					if ( item.amount > Data.item.get(item.cdbEntry).stack.int() ) {
						item.amount -= Data.item.get(item.cdbEntry).stack.int();
						slot.item = Item.fromCdbEntry(item.cdbEntry, slot.containmentEntity, Data.item.get(item.cdbEntry).stack.int());
						slot.item.containerEntity = slot.containmentEntity;
					} else {
						slot.item = item;
						slot.item.containerEntity = slot.containmentEntity;
						return slot;
					}
				} else if ( (slot.item.amount + item.amount) > Data.item.get(item.cdbEntry).stack.int() ) {
					item.amount -= Data.item.get(item.cdbEntry).stack.int() - slot.item.amount;
					slot.item.amount = Data.item.get(item.cdbEntry).stack.int();
				} else {
					slot.item.amount += item.amount;
					slot.item.containerEntity = slot.containmentEntity;
					item.amount = 0;
					return slot;
				}
				slot = findSameItem(item, ignoreSlot);
				if ( slot == null ) slot = getFreeSlot(ignoreSlot);
				if ( slot == null ) break;
			} while( item.amount > 0 );
			return slot;
		};

		if ( slot != null
			&& slot.item.amount < Data.item.get(item.cdbEntry).stack.int()
			&& doStack
		) {
			return splitAndFill();
		}

		if ( slot == null || !doStack ) {
			slot = getFreeSlot();
			if ( slot == null ) {
				slot.containmentEntity.dropItem(item);
				return null;
			}
			return splitAndFill();
		}

		return slot;
	}

	public function findItemSlot( item : en.Item ) : InventoryCell {
		for ( i in grid ) for ( j in i ) if ( j.item == item ) return j;
		return null;
	}
}

/** 
	логический держатель для Item
**/
class InventoryCell implements Serializable {
	@:s public var item(default, set) : en.Item;
	@:s public var containmentEntity : Entity;

	public var containerType : ItemPresense = Inventory;

	public var onAddItem : Item -> Void;

	inline function set_item( v : en.Item ) {
		if ( v != null ) {
			v.containerEntity = containmentEntity;
			v.itemPresense = containerType;

			if ( onAddItem != null )
				onAddItem(v);
		}

		return item = v;
	}

	public function new( containmentEntity : Entity ) {
		this.containmentEntity = containmentEntity;
	}
}

/**
	ui обёртка над InventoryGrid
**/
class UICellGrid extends h2d.Object {
	public var itemCount(get, never) : Int;

	function get_itemCount() {
		var cout = 0;
		for ( i in inventoryGrid.grid ) for ( j in i ) if ( j.item != null ) cout++;
		return cout;
	}

	public var inventoryGrid : InventoryGrid;
	public var flowGrid : Array<Array<InventoryCellFlow>> = [];
	public var cellWidth : Int;
	public var cellHeight : Int;

	// public dynamic function giveItem( item : en.Item,
	// 	?ignoreSlot : InventoryCell,
	// 	?ignoreFull : Bool = true,
	// 	?doStack : Bool = true ) : InventoryCell
	// 	return null;

	public function disableGrid() {
		for ( yi => y in flowGrid ) for ( xi => x in y ) {
			var cell = inventoryGrid.grid[yi][xi];
			if ( cell.item == null || cell.item.isDisposed ) x.inter.cursor = Default;
		}
	}

	public function enableGrid() {
		for ( yi => y in flowGrid ) for ( xi => x in y ) {
			var cell = inventoryGrid.grid[yi][xi];
			if ( cell.item == null || cell.item.isDisposed ) x.inter.cursor = Button;
		}
	}

	public function new( inventoryGrid : InventoryGrid, ?cellWidth : Int = 0, ?cellHeight : Int = 0, ?parent : h2d.Object ) {
		super(parent);

		this.inventoryGrid = inventoryGrid;

		this.cellWidth = cellWidth;
		this.cellHeight = cellHeight;

		// giveItem = grid.giveItem.bind(_, containmentEntity, _, _, _);

		for ( yi => y in inventoryGrid.grid ) {
			flowGrid.push([]);
			for ( xi => x in y )
				flowGrid[yi].push(new InventoryCellFlow(x, cellWidth, cellHeight));
		}
	}
}

class InventoryCellFlow extends h2d.Flow {
	public var cell : InventoryCell;

	public var inter : EventInteractive;

	public function new( cell : InventoryCell, ?width : Int = 0, ?height : Int = 0, ?parent : h2d.Object ) {
		super(parent);

		this.cell = cell;
		cell.onAddItem = ( v : Item ) -> {
			if ( v.itemSprite == null ) {
				new ItemSprite(v, this);
			} else {
				addChild(v.itemSprite);
			}
			if ( getProperties(v.itemSprite) != null )
				getProperties(v.itemSprite).align(Middle, Middle);
		};

		fillWidth = fillHeight = true;

		this.minWidth = width;
		this.minHeight = height;

		inter = new ch2.ui.EventInteractive(width, height, this);
		inter.cursor = Default;
		inter.enableRightButton = true;
		inter.propagateEvents = true;
		getProperties(inter).isAbsolute = true;

		inter.onPush = function ( e : Event ) {

			switch e.button {
				case 0:
					// lmb
					// shift
					// кликаем где угодно, кроме основной сетки игрока
					if ( Key.isDown(Key.SHIFT) ) {
						if ( cell.item != null ) {
							if ( (!cell.containmentEntity.isOfType(Player)
								|| cell.item.itemPresense != Belt) //
							) {
								// предмет либо в поясе либо в сундуке, переносим в соновной инвентарь игрока

								var sameItemCell = Player.inst.inventory.findSameItem(cell.item, cell);

								// будет неприкольно, если мы добавим предмет самого в себя
								var freeSlot = (sameItemCell != null && sameItemCell != cell) ? sameItemCell : Player.inst.inventory.getFreeSlot();
								if ( freeSlot != null ) {
									Player.inst.inventory.giveItem(cell.item);
									Player.inst.ui.belt.deselectCells();

									cell.item = null;
								}
							}

							// кликаем в сетке игрока
							if ( Key.isDown(Key.SHIFT)
								&& (cell.containmentEntity.isOfType(Player)) ) {
								for ( w in Window.ALL ) {
									if ( w.win.visible && Std.isOfType(w, ChestWin) ) {
										if ( cast(w, ChestWin).cellGrid.inventoryGrid.giveItem(cell.item) != null ) {
											cell.item = null;
											return;
										}
									}
								}

								// если мы здесь, значит, что не нашлось пустых ячеек в открытых сундуках и мы кидаем предмет в пояс
								if ( Player.inst.inventory.giveItem(cell.item) != null ) {
									cell.item = null;
									return;
								}
							}
						}

						// no shift

						// if (
						// 	!Key.isDown(Key.SHIFT)
						// 	&& cell.item.itemPresense == Belt
						// 	&& !Player.inst.ui.inventory.win.visible
						// ) {
						// 	// selecting item by click in belt
						// 	// cell is in the belt and is clicked while player inventory is hidden
						// 	for ( i => slot in Player.inst.inventory.beltLayer ) {
						// 		if ( slot.item == cell.item ) Player.inst.ui.belt.selectCell(i + 1);
						// 		continue;
						// 	}
						// }
					}

					if ( !Key.isDown(Key.SHIFT) // && cell.containerType == Inventory
					) {
						var tempItem = Player.inst.holdItem;
						Player.inst.holdItem = cell.item;
						cell.item = tempItem;
					}

				// if (
				// 	!Key.isDown(Key.SHIFT) &&
				// 	(cell.item == null
				// 		|| !Player.inst.itemInBelt(cell.item)
				// 		|| Player.inst.ui.inventory.win.visible) //
				// ) {

				// 	if (
				// 		Player.inst.holdItem == null
				// 		|| !Player.inst.holdItem.isInBelt()
				// 		|| Player.inst.holdItem == cell.item
				// 	) {
				// 		// swapping with player's cursor
				// 		var tempItem = (
				// 			Player.inst.holdItem != null
				// 			&& Player.inst.holdItem.isInBelt()
				// 			&& Player.inst.holdItem == cell.item
				// 		) ? null : Player.inst.holdItem;

				// 		Player.inst.holdItem = cell.item;
				// 		cell.item = tempItem;
				// 	}

				// 	if ( Player.inst.holdItem != null && Player.inst.holdItem.itemSprite != null && isInBelt ) {
				// 		Player.inst.putItemInCursor(Player.inst.holdItem.itemSprite);
				// 		Player.inst.ui.belt.deselectCells();
				// 	}
				// }
				case 1:
					// rmb
					if ( (Player.inst.holdItem == null ||
						(Player.inst.holdItem != null &&
							Player.inst.holdItem.itemPresense == Belt
						)) && cell.item != null
					) {
						Player.inst.holdItem = Item.fromCdbEntry(cell.item.cdbEntry, Player.inst, Math.ceil(cell.item.amount - cell.item.amount / 2));
						cell.item.amount = Std.int(cell.item.amount / 2);
					}
			}
		}
	}

	override function onRemove() {
		super.onRemove();
		cell.onAddItem = null;
	}
}
