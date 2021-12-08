package ui;

import en.structures.Chest;
import hxd.Key;
import ch2.ui.EventInteractive;
import en.player.Player;
import h2d.Flow;
import h2d.RenderContext;
import hxd.Event;

class InventoryCell extends h2d.Flow {
	public var item(default, set) : en.Item;
	public var inter : EventInteractive;

	var containmentEntity : Entity;

	inline function set_item( v : en.Item ) {
		if ( v != null ) {
			v.containerEntity = containmentEntity;
			inter.addChild(v);
			v.x = inter.width / 2;
			v.y = inter.height / 2;
			v.setScale(1);
		}

		return item = v;
	}

	public function new( ?width : Int = 0, ?height : Int = 0, containmentEntity : Entity, ?parent : h2d.Object ) {
		super(parent);
		this.containmentEntity = containmentEntity;

		inter = new ch2.ui.EventInteractive(width, height, this);
		inter.cursor = Default;
		inter.enableRightButton = true;

		inter.onPush = function ( e : Event ) {

			switch e.button {
				case 0:
					// lmb
					// shift
					// кликаем где угодно, кроме основной сетки игрока
					if ( Key.isDown(Key.SHIFT)
						&& item != null
						&& (item.isInBelt() || !containmentEntity.isOfType(Player)) ) {

						var sameItemCell = Player.inst.cellGrid.grid.findSameItem(item, this);

						// будет неприкольно, если мы добавим предмет самого в себя
						var freeSlot = sameItemCell != null && sameItemCell != this ? sameItemCell : Player.inst.cellGrid.grid.getFreeSlot();
						if ( freeSlot != null ) {
							// переносим
							Player.inst.cellGrid.giveItem(item, this);
							Player.inst.ui.belt.deselectCells();

							item = null;
						}
					}

					// кликаем в сетке игрока
					if ( Key.isDown(Key.SHIFT)
						&& item != null
						&& (containmentEntity.isOfType(Player)) ) {
						for ( w in Window.ALL ) {
							if ( w.win.visible && Std.isOfType(w, ChestWin) ) {
								if ( cast(w, ChestWin).cellGrid.giveItem(item) != null ) {
									item = null;
									return;
								}
							}
						}

						// если мы здесь, значит, что не нашлось пустых ячеек в открытых сундуках и мы кидаем предмет в пояс
						if ( Player.inst.ui.belt.grid.giveItem(item, Player.inst) != null ) {
							item = null;
							return;
						}
					}

					// no shift
					if (
						!Key.isDown(Key.SHIFT)
						&& item != null
						&& item.isInBelt()
						&& !Player.inst.ui.inventory.win.visible
					) {

						// cell is in the belt and is clicked while player inventory is hidden
						for ( i => slot in Player.inst.cellGrid.grid[Player.inst.cellGrid.grid.length - 1] ) {
							if ( slot.item == item ) Player.inst.ui.belt.selectCell(i + 1);
							continue;
						}
					}

					if (
						!Key.isDown(Key.SHIFT)
						&& (item == null
							|| (!item.isInBelt() || Player.inst.ui.inventory.win.visible)) ) {

						var isInBelt = item != null && item.isInBelt();

						if (
							Player.inst.holdItem == null
							|| !Player.inst.holdItem.isInBelt()
							|| Player.inst.holdItem == item
						) {
							// swapping with player's cursor
							var tempItem = (
								Player.inst.holdItem != null
								&& Player.inst.holdItem.isInBelt()
								&& Player.inst.holdItem == item
							) ? null : Player.inst.holdItem;

							Player.inst.holdItem = item;
							item = tempItem;
						}

						if ( Player.inst.holdItem != null && isInBelt ) {
							Player.inst.putItemInCursor(Player.inst.holdItem);
							Player.inst.ui.belt.deselectCells();
						}
					}
				case 1:
					// rmb
					if ( Player.inst.holdItem == null || (Player.inst.holdItem != null && Player.inst.holdItem.isInBelt()) ) {
						Player.inst.holdItem = Item.fromCdbEntry(item.cdbEntry, Math.ceil(item.amount - item.amount / 2));
						item.amount = Std.int(item.amount / 2);
					}
			}
		}

		getProperties(inter).isAbsolute = true;
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
	}

	public override function onRemove() {
		super.onRemove();
	}
}

@:forward
abstract InventoryGrid( Array<Array<InventoryCell>> ) {

	public function new( grid : Array<Array<InventoryCell>> ) {
		this = grid;
	}

	@:arrayAccess
	inline function get( key : Int ) return this[key];

	public function disableGrid() {
		for ( i in this ) for ( j in i ) {
			if ( j.item == null || j.item.isDisposed ) j.inter.cursor = Default;
		}
	}

	public function enableGrid() {
		for ( i in this ) for ( j in i ) {
			if ( j.item == null || j.item.isDisposed ) j.inter.cursor = Button;
		}
	}

	public function getFreeSlot( ?ignoreSlot : InventoryCell ) : InventoryCell {
		for ( i in this ) for ( j in i )
			if ( (ignoreSlot == null || ignoreSlot != j)
				&& (j.item == null || j.item.isDisposed) )
				return j;
		return null;
	}

	public function findItemKind( kind : Data.Items, amount : Int, except : Array<InventoryCell> ) {
		function isChecked( cell : InventoryCell ) {
			for ( i in except ) if ( cell == i ) return true;
			return false;
		}
		for ( i in this ) for ( j in i ) if ( j.item != null
			&& !isChecked(j)
			&& Data.items.get(j.item.cdbEntry) == kind
			&& j.item.amount >= amount ) return j;
		return null;
	}
	/**
		@param ignoreFull if true, will return same item even if they are full
	**/
	public function findSameItem( item : Item, ?ignoreSlot : InventoryCell, ?ignoreFull : Bool = true ) : InventoryCell {

		for ( i in this ) for ( j in i )
			if ( (ignoreSlot == null || ignoreSlot != j)
				&& j.item != null
				&& !j.item.isDisposed
				&& j.item.isSameTo(item)
				&& (j.item.amount < Data.items.get(item.cdbEntry).stack.int() || !ignoreFull) )
				return j;
		return null;
	}
	/**
		@param doStack if false, will ignore same items below maximum capacity and will not stack with them 
		@param sourceSlot if specified, will not put item into it
	**/
	public function giveItem(
		item : en.Item,
		containmentEntity : Entity,
		?ignoreSlot : InventoryCell,
		?ignoreFull : Bool = true,
		?doStack : Bool = true ) : InventoryCell {

		// Поиск Item в сетке, amount которого меньше или не равен stack из cdbEntry, и добавление к нему
		var slot = findSameItem(item, ignoreSlot, ignoreFull);
		var splitAndFill : Void -> InventoryCell = () -> {
			do {
				if ( slot.item == null || slot.item.isDisposed ) {
					// Пустая ячейка
					if ( item.amount > Data.items.get(item.cdbEntry).stack.int() ) {
						item.amount -= Data.items.get(item.cdbEntry).stack.int();
						slot.item = Item.fromCdbEntry(item.cdbEntry, Data.items.get(item.cdbEntry).stack.int());
						slot.item.containerEntity = containmentEntity;
					} else {
						slot.item = item;
						slot.item.containerEntity = containmentEntity;
						return slot;
					}
				} else if ( (slot.item.amount + item.amount) > Data.items.get(item.cdbEntry).stack.int() ) {
					item.amount -= Data.items.get(item.cdbEntry).stack.int() - slot.item.amount;
					slot.item.amount = Data.items.get(item.cdbEntry).stack.int();
				} else {
					slot.item.amount += item.amount;
					slot.item.containerEntity = containmentEntity;
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
			&& slot.item.amount < Data.items.get(item.cdbEntry).stack.int()
			&& doStack
		) {
			return splitAndFill();
		}

		if ( slot == null || !doStack ) {
			slot = getFreeSlot();
			if ( slot == null ) {
				containmentEntity.dropItem(item);
				return null;
			}
			return splitAndFill();
		}

		return slot;
	}

	public function findAndReplaceItem( item : en.Item, ?to : en.Item = null ) : en.Item {
		for ( i in this ) for ( j in i ) if ( j.item == item ) {
			j.item.remove();
			j.item = to;
			return j.item;
		}
		return null;
	}

	public function findItemSlot( item : en.Item ) : InventoryCell {
		for ( i in this ) for ( j in i ) if ( j.item == item ) return j;
		return null;
	}
}

class CellGrid extends h2d.Object {
	var player(get, never) : Player;

	inline function get_player() return Player.inst;

	public var itemCount(get, never) : Int;

	function get_itemCount() {
		var cout = 0;
		for ( i in grid ) for ( j in i ) if ( j.item != null ) cout++;
		return cout;
	}

	public var grid : InventoryGrid;
	public var width : Int;
	public var height : Int;

	public var cellWidth : Int;
	public var cellHeight : Int;

	public var containmentEntity : Entity;

	public dynamic function giveItem( item : en.Item,
		?ignoreSlot : InventoryCell,
		?ignoreFull : Bool = true,
		?doStack : Bool = true ) : InventoryCell
		return null;

	public function new( width : Int, height : Int, ?cellWidth : Int = 0, ?cellHeight : Int = 0, containmentEntity : Entity, ?parent : h2d.Object ) {
		super(parent);

		this.containmentEntity = containmentEntity;

		this.width = width;
		this.height = height;

		this.cellWidth = cellWidth;
		this.cellHeight = cellHeight;

		grid = new InventoryGrid([
			for ( _ in 0...height ) [
				for ( _ in 0...width ) new InventoryCell(cellWidth, cellHeight, containmentEntity, this)
			]
		]);

		giveItem = grid.giveItem.bind(_, containmentEntity, _, _, _);
	}
}
