package en;

import hxbit.Serializable;
import cherry.soup.EventSignal.EventSignal0;
import en.player.Player;
import hxbit.NetworkSerializable;
import ui.ItemSprite;

enum ItemPresense {
	Cursor;
	Belt;
	Inventory;
}

class Item implements NetworkSerializable {
	@:s
	public var cdbEntry : Data.ItemKind;

	@:s
	public var amount( default, set ) : Int = 1;

	public var onStructureUse = new EventSignal0();
	public var onPlayerHold = new EventSignal0();
	public var onPlayerRemove = new EventSignal0();

	@:s
	public var containerEntity : Entity;
	public var itemPresense : ItemPresense;

	@:s public var isDisposed : Bool;

	public var itemSprite : ItemSprite;

	inline function set_amount( v : Int ) {
		if ( v <= 0 ) dispose();

		if ( itemSprite != null ) itemSprite.changeAmount( v );
		return amount = v;
	}

	inline public function isSameTo( item : Item ) : Bool return '${item}' == '$this' && item.cdbEntry == cdbEntry;

	public function new( cdbEntry : Data.ItemKind ) {
		this.cdbEntry = cdbEntry;
		isDisposed = false;

		enableReplication = true;
	}

	inline public function dispose() {
		if ( Player.inst != null && this == Player.inst.holdItem ) Player.inst.holdItem = null;
		isDisposed = true;
	}

	public static function fromCdbEntry( cdbEntry : Data.ItemKind, containerEntity : Entity, ?amount : Int = 1 ) {
		var item : Item = null;

		var entClasses = CompileTime.getAllClasses( Item );
		for ( e in entClasses ) {
			if ( eregCompTimeClass.match( '$e'.toLowerCase() )
				&& eregCompTimeClass.matched( 1 ) == Data.item.get( cdbEntry ).id.toString().toLowerCase() ) {
				item = Type.createInstance( e, [cdbEntry] );
			}
		}
		// if(item == null && Data.cdbEntry)
		item = item == null ? new Item( cdbEntry ) : item;
		item.amount = amount;
		item.containerEntity = containerEntity;

		return item;
	}
}

class StackExtender {
	static inline public function int( i : Data.Item_stack ) {
		return switch i {
			case _1: 1;
			case _4: 4;
			case _16: 16;
			case _64: 64;
		}
	}
}
