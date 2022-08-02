package ui.core;

import ch2.ui.EventInteractive;
import cherry.soup.EventSignal.EventSignal1;
import en.Entity;
import en.Item;
import en.player.Player;
import en.util.item.InventoryCell;
import en.util.item.ItemManipulations;
import h2d.Flow;
import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import hxbit.Serializable;
import hxd.Event;
import hxd.Key;
import net.transaction.TransactionFactory;

/**
	логический держатель сетки для Item
**/
class InventoryGrid implements Serializable {

	@:s public var grid : Array<Array<InventoryCell>>;
	@:s public var width : Int;
	@:s public var height : Int;
	@:s public var type( default, null ) : ItemPresense;

	public function new( width : Int, height : Int, type : ItemPresense, ?preparedGrid : Array<Array<InventoryCell>>, ?containmentEntity : Entity ) {
		this.width = width;
		this.height = height;
		this.type = type;

		if ( preparedGrid != null )
			for ( row in preparedGrid )
				for ( cell in row )
					cell.type = type;

		grid = preparedGrid != null ? preparedGrid : [
			for ( _ in 0...height ) [
				for ( _ in 0...width ) new InventoryCell( type, containmentEntity )
			]
		];
	}

	public function getFreeSlot( ?ignoreCell : InventoryCell ) : InventoryCell {
		for ( i in grid ) for ( cell in i )
			if ( ignoreCell != cell && cell.item == null ) return cell;
		return null;
	}

	public function findItemKind( kind : Data.Item, amount : Int, ?except : Array<InventoryCell> ) {
		inline function isChecked( cell : InventoryCell ) {
			var result = false;
			for ( i in except ) if ( cell == i ) result = true;
			return result;
		}
		for ( i in grid ) for ( cell in i )
			if ( cell.item != null
				&& ( except != null && !isChecked( cell ) )
				&& Data.item.get( cell.item.cdbEntry ) == kind
				&& cell.item.amount >= amount
			) return cell;
		return null;
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer, ?finalize ) @:privateAccess {
		for ( i in grid )
			for ( cell in i )
				if ( ctx.refs.exists( cell.__uid ) ) {
					cell.unreg( host, ctx, finalize );
				}
	}

	/**
		@param ignoreSlot slot to be ignored whle searching
		@param ignoreFull will ignore full stacks if true
	**/
	public function findSameItem( item : Item, ignoreFull = false, returnEmpty = false ) : InventoryCell {
		var resultCell = null;
		for ( i in grid ) for ( cell in i ) {
			if ( returnEmpty && cell.item == null && resultCell == null ) resultCell = cell;
			if ( item != cell.item
				&& cell.item != null
				&& ( !ignoreFull || !cell.item.isStackFull )
				&& cell.item.isSameTo( item ) ) return cell;
		}
		return resultCell;
	}

	/**
		@param doStack if false, will ignore same items below maximum capacity and will not stack with them 
		@param sourceSlot if specified, will not put item into it
	**/
	public function giveItem(
		from : InventoryCell,
		?ignoreFull : Bool = true,
		?doStack : Bool = true ) : InventoryCell {

		var item = from.item;
		function splitAndFill( slot : InventoryCell ) : InventoryCell {
			do {
				if ( slot.item == null ) {
					// Пустая ячейка
					slot.item = item;
					from.item = null;
					return slot;
				} else if ( ( slot.item.amount + item.amount ) > item.stack ) {
					item.amount -= item.stack - slot.item.amount;
					slot.item.amount = item.stack;
				} else {
					// если не надо делить предметы
					slot.item.amount += item.amount;
					slot.item.containerEntity = slot.containmentEntity;
					from.item = null;
					return slot;
				}
				slot = findSameItem( item );
				if ( slot == null ) slot = getFreeSlot();
				if ( slot == null ) break;
			} while( from.item != null );
			return slot;
		}
		// Поиск Item в сетке, amount которого меньше или не равен stack из cdbEntry, и добавление к нему
		var slot = findSameItem( item, ignoreFull, true );

		if ( slot != null // && slot.item.amount < item.stack
			&& doStack
		) {
			return splitAndFill( slot );
		}

		// if ( slot == null || !doStack ) {
		// 	slot = getFreeSlot();

		// 	if ( slot == null ) {
		// 		slot.containmentEntity.dropItem( item );
		// 		return null;
		// 	}
		// 	return splitAndFill( slot );
		// }

		return slot;
	}
}

/**
	ui обёртка над InventoryGrid
**/
class InventoryCellFlowGrid extends h2d.Object {

	public var itemCount( get, never ) : Int;

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
			if ( cell.item == null ) x.inter.cursor = Default;
		}
	}

	public function enableGrid() {
		for ( yi => y in flowGrid ) for ( xi => x in y ) {
			var cell = inventoryGrid.grid[yi][xi];
			if ( cell.item == null ) x.inter.cursor = Button;
		}
	}

	public function new( inventoryGrid : InventoryGrid, ?cellWidth : Int = 0, ?cellHeight : Int = 0, ?parent : h2d.Object ) {
		super( parent );

		this.inventoryGrid = inventoryGrid;

		this.cellWidth = cellWidth;
		this.cellHeight = cellHeight;

		for ( yi => y in inventoryGrid.grid ) {
			flowGrid.push( [] );
			for ( xi => x in y )
				flowGrid[yi].push( new InventoryCellFlow( x, cellWidth, cellHeight ) );
		}
	}
}

class InventoryCellFlow extends h2d.Flow {

	public var cell : InventoryCell;
	public var inter : EventInteractive;

	public function new( cell : InventoryCell, ?width : Int = 0, ?height : Int = 0, ?parent : h2d.Object ) {
		super( parent );

		this.cell = cell;

		fillWidth = fillHeight = true;

		this.minWidth = this.maxWidth = width;
		this.minHeight = this.maxHeight = height;

		inter = new ch2.ui.EventInteractive( width, height, this );
		inter.cursor = Default;
		inter.enableRightButton = true;
		inter.propagateEvents = true;
		getProperties( inter ).isAbsolute = true;

		if ( cell.onSetItem == null ) cell.onSetItem = new EventSignal1();

		cell.onSetItem.add( ( v : Item ) -> {
			inter.cursor = if ( v == null && Player.inst != null && Player.inst.holdItem.item == null ) Default else Button;

			if ( v == null ) {
				if ( cell.item != null && cell.item.itemSprite != null )
					cell.item.itemSprite.remove();
				return;
			}

			if ( v.itemSprite == null ) {
				new ItemSprite( v, this );
			} else {
				addChild( v.itemSprite );
			}

			if ( getProperties( v.itemSprite ) != null )
				getProperties( v.itemSprite ).align( Middle, Middle );
		} );
		if ( cell.item != null ) cell.onSetItem.dispatch( cell.item );

		function itemInter( e : Event ) {
			switch e.button {
				case 0:
					// lmb
					// shift
					// кликаем где угодно, кроме основной сетки игрока
					if ( Key.isDown( Key.SHIFT ) ) {
						if ( cell.item != null ) {
							if ( cell.type == PlayerInventory ) {
								ItemManipulations.fromPlayerInvToAnyInventory( cell );
							} else {
								ItemManipulations.toPlayer( cell );
							}
						}
					} else {
						// lmb
						// no shift
						if ( Player.inst.holdItem.item != null
							&& cell.item != null
							&& Player.inst.holdItem.item.isSameTo( cell.item )
							&& !cell.item.isStackFull
						) {
							TransactionFactory.itemPour( Player.inst.holdItem, cell, r -> utils.sfx.Sfx.playItemPickupSnd() );
							return;
						}
						if ( //
							(
								Player.inst.holdItem.item != null
								|| cell.item != null
							) && (
								cell.type != PlayerBelt
								|| Player.inst.pui.inventory.isVisible
								|| Player.inst.holdItem.item != null
							)
							&& ItemManipulations.getCursorSwappingCondition( this )
						) {
							TransactionFactory.itemsSwap( Player.inst.holdItem, cell, r -> utils.sfx.Sfx.playItemPickupSnd() );
						}
					}
				case 1:
					// rmb
					if ( cell.item != null
						&& cell.item.amount > 1
						&& Player.inst.holdItem.item == null
						&& (
							cell.type != PlayerBelt
							|| Player.inst.pui.inventory.isVisible
						) ) {
							TransactionFactory.itemSplit( cell, Player.inst.holdItem, r -> utils.sfx.Sfx.playItemPickupSnd() );
					}
			}
		}

		inter.onPushEvent.add( itemInter );
	}

	override function onRemove() {
		super.onRemove();
		cell.onSetItem = null;
	}
}
