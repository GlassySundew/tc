package ui;

import h2d.RenderContext;
import h2d.Flow;
import ch2.ui.EventInteractive;
import cherry.soup.EventSignal.EventSignal0;
import cherry.soup.EventSignal.EventSignal1;
import ui.player.Inventory;
import haxe.Constraints.Function;
import h3d.scene.Object;
import h2d.ScaleGrid;
import hxd.Event;
import en.player.Player;

class InventoryCell extends h2d.Flow {
	public var item(default, set) : en.Item;
	public var inter : EventInteractive;

	inline function set_item( v : en.Item ) {
		if ( v != null ) {
			inter.addChild(v);
			v.x = inter.width / 2;
			v.y = inter.height / 2;
			v.setScale(1);
		}

		return item = v;
	}

	public function new( ?width : Int = 0, ?height : Int = 0, ?parent : h2d.Object ) {
		super(parent);
		inter = new ch2.ui.EventInteractive(width, height, this);
		// inter.visible = false;
		inter.cursor = Default;
		inter.onPush = function ( e : Event ) {
			if ( Player.inst.holdItem != null && !Player.inst.holdItem.isDisposed && Player.inst.holdItem.isInCursor() && (item == null || item.isDisposed) ) {
				item = Game.inst.player.holdItem;
				Game.inst.player.holdItem = null;
				// Когда кладём предмет в слот, все курсоры сеток должны быть выключены
				for ( i in Inventory.ALL ) i.invGrid.disableGrid();
			}
		}
		getProperties(inter).isAbsolute = true;
	}
	override function sync(ctx:RenderContext) {
		super.sync(ctx);
	}
	public override function onRemove() {
		super.onRemove();
	}
}

class CellGrid extends h2d.Object {
	var player(get, never) : Player;

	inline function get_player() return Player.inst;

	public var itemCout(get, never) : Int;

	function get_itemCout() {
		var cout = 0;
		for ( i in grid ) for ( j in i ) if ( j.item != null ) cout++;
		return cout;
	}

	public var grid : Array<Array<InventoryCell>>;
	public var width : Int;
	public var height : Int;

	public var cellWidth : Int;
	public var cellHeight : Int;

	public function new( width : Int, height : Int, ?cellWidth : Int = 0, ?cellHeight : Int = 0, ?parent : h2d.Object ) {
		super(parent);

		this.width = width;
		this.height = height;

		this.cellWidth = cellWidth;
		this.cellHeight = cellHeight;

		grid = [
			for ( _ in 0...height ) [for ( _ in 0...width ) new InventoryCell(cellWidth, cellHeight, this)]
		];
	}

	public function disableGrid() {
		for ( i in grid ) for ( j in i ) {
			if ( j.item == null || j.item.isDisposed ) j.inter.cursor = Default;
		}
	}

	public function enableGrid() {
		for ( i in grid ) for ( j in i ) {
			if ( j.item == null || j.item.isDisposed ) j.inter.cursor = Button;
		}
	}

	public function getFreeSlot() : InventoryCell {
		for ( i in grid ) for ( j in i ) if ( j.item == null || j.item.isDisposed ) return j;
		return null;
	}

	public function findItemKind( kind : Items, amount : Int, except : Array<InventoryCell> ) {
		function isChecked( cell : InventoryCell ) {
			for ( i in except ) if ( cell == i ) return true;
			return false;
		}
		for ( i in grid ) for ( j in i ) if ( j.item != null
			&& !isChecked(j)
			&& Data.items.get(j.item.cdbEntry) == kind
			&& j.item.amount >= amount ) return j;
		return null;
	}

	public function findSameItem( item : Item, ?ignoreFull : Bool = true ) : InventoryCell {
        
		for ( i in grid ) for ( j in i ) if ( j.item != null && !j.item.isDisposed && j.item.isSameTo(item)
			&& (j.item.amount < Data.items.get(item.cdbEntry).stack.int() || !ignoreFull) ) return j;
		return null;
	}

	public function giveItem( item : en.Item, containerEntity : Entity, ?ignoreFull : Bool = true, ?doStack : Bool = true ) : InventoryCell {
		// Поиск Item в сетке, amount которого меньше или не равен stack из cdbEntry, и добавление к нему
		var slot = findSameItem(item, ignoreFull);

		var splitAndFill : Void -> InventoryCell = () -> {
			do {
				if ( slot.item == null || slot.item.isDisposed ) {
					// Пустая ячейка
					if ( item.amount > Data.items.get(item.cdbEntry).stack.int() ) {
						item.amount -= Data.items.get(item.cdbEntry).stack.int();
						slot.item = Item.fromCdbEntry(item.cdbEntry, Data.items.get(item.cdbEntry).stack.int());
						slot.item.containerEntity = containerEntity;
					} else {
						slot.item = item;
						slot.item.containerEntity = containerEntity;
						return slot;
					}
				} else if ( (slot.item.amount + item.amount) > Data.items.get(item.cdbEntry).stack.int() ) {
					item.amount -= Data.items.get(item.cdbEntry).stack.int() - slot.item.amount;
					slot.item.amount = Data.items.get(item.cdbEntry).stack.int();
				} else {
					slot.item.amount += item.amount;
					slot.item.containerEntity = containerEntity;
					item.amount = 0;
					return slot;
				}
				slot = findSameItem(item);
				if ( slot == null ) slot = getFreeSlot();
				if ( slot == null ) break;
			} while( item.amount > 0 );
			return slot;
		};

		if ( slot != null && slot.item.amount < Data.items.get(item.cdbEntry).stack.int() && doStack ) {
			return splitAndFill();
		} else {
			slot = getFreeSlot();
			if ( slot == null ) {
				containerEntity.dropItem(item);
				return null;
			}
			return splitAndFill();
		}

		return slot;
	}

	public function findAndReplaceItem( item : en.Item, ?to : en.Item = null ) : en.Item {
		for ( i in grid ) for ( j in i ) if ( j.item == item ) {
			j.item.remove();
			j.item = to;
			return j.item;
		}
		return null;
	}

	public function findItemSlot( item : en.Item ) : InventoryCell {
		for ( i in grid ) for ( j in i ) if ( j.item == item ) return j;
		return null;
	}

	@:allow(Interactive) function dispose() {}
}
