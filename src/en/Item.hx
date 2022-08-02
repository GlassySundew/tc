package en;

import cherry.soup.EventSignal.EventSignal1;
import cherry.soup.EventSignal.EventSignal0;
import hxbit.NetworkSerializable;
import ui.core.ItemSprite;

enum abstract ItemPresense( Int ) from Int to Int {

	var Cursor = 0;
	var PlayerBelt = 1;
	var PlayerInventory = 2;
	var Chest = 3;
}

class Item implements NetworkSerializable {

	@:s public var cdbEntry : Data.ItemKind;
	@:s public var amount( default, set ) : Int = 1;
	@:s public var containerEntity : Entity;

	public var onStructureUse = new EventSignal0();
	public var onPlayerHold = new EventSignal0();
	public var onPlayerRemove = new EventSignal0();

	public var onAmountChanged = new EventSignal1<Int>();

	public var itemPresense : ItemPresense;
	public var itemSprite : ItemSprite;

	public var stack( default, null ) : Int;

	inline function set_amount( v : Int ) {
		if ( onAmountChanged != null ) onAmountChanged.dispatch( v );
		return amount = v;
	}

	public var isStackFull( get, never ) : Bool;

	inline function get_isStackFull() : Bool return amount >= Data.item.get( cdbEntry ).stack.int();

	inline public function isSameTo( item : Item ) : Bool return item.cdbEntry == cdbEntry;

	public function new( cdbEntry : Data.ItemKind ) {
		this.cdbEntry = cdbEntry;
		init();
	}

	function init() {
		stack = stackAmount( this );
		enableAutoReplication = true;
	}

	public static inline function stackAmount( item : Item ) return Data.item.get( item.cdbEntry ).stack.int();

	public static function fromCdbEntry( cdbEntry : Data.ItemKind, containerEntity : Entity, amount = 1 ) {
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

	static public function int( i : Data.Item_stack ) {
		return switch i {
			case _1: 1;
			case _4: 4;
			case _16: 16;
			case _64: 64;
		}
	}
}
