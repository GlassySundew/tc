package ui.core;

import en.Item;
import dn.heaps.slib.HSprite;
import cherry.soup.EventSignal.EventSignal0;
import ch2.ui.EventInteractive;
import dn.heaps.input.ControllerAccess;
import game.client.ControllerAction;
import h2d.Flow;
import h2d.Object;
import ui.domkit.TextLabelComp;
import util.Assets;

/**
	ui обёртка над en.Item
**/
class ItemSprite extends Flow {

	public var spr : HSprite;
	public var eventInteractive : EventInteractive;
	public var amountLabel : TextLabelComp;
	public var item : Item;

	public var onAdded : EventSignal0 = new EventSignal0();

	var tooltip : TextLabelComp;
	var ca : ControllerAccess<ControllerAction>;

	var displayText : String = "";

	public final defaultContainerSize = 18;

	public function new( item : Item, ?parent : h2d.Object ) {
		super( parent );

		ca = Main.inst.controller.createAccess();

		this.item = item;
		item.itemSprite = this;
		item.onAmountChanged.add( changeAmount );

		horizontalAlign = Middle;
		verticalAlign = Middle;

		spr = new HSprite( Assets.items, this );

		spr.set( Data.item.get( item.cdbEntry ).atlas_name );
		displayText = Data.item.get( item.cdbEntry ).display_name;

		spr.tile.getTexture().filter = Nearest;

		fillHeight = fillWidth = true;

		amountLabel = new TextLabelComp( '${item.amount}', Assets.fontPixel, this );
		amountLabel.scale( .5 );
		amountLabel.dom.setAttribute( "position", VIdent( "absolute" ) );
		amountLabel.dom.setAttribute( "valign", VIdent( "bottom" ) );
		amountLabel.dom.setAttribute( "halign", VIdent( "right" ) );
		amountLabel.shadowed_text.dom.setAttribute( "offset-y", VInt( -1 ) );
		amountLabel.cornersRounder.radius = 6;
		amountLabel.cornersRounder.edgeSoftness = 1;

		eventInteractive = new EventInteractive( spr.tile.width, spr.tile.height, spr );
		eventInteractive.enableRightButton = true;

		eventInteractive.onOver = function ( e : hxd.Event ) {
			tooltip = new TextLabelComp( displayText, Assets.fontPixel, Boot.inst.s2d );
			updateTooltip();
		}

		eventInteractive.onMove = function ( e ) {
			updateTooltip();
		}

		eventInteractive.onOut = function ( e : hxd.Event ) {
			tooltip.remove();
		}

		eventInteractive.onFocusEvent.add( function ( e : hxd.Event ) {} );

		eventInteractive.onPush = ( e ) -> {
			tooltip.remove();
		}

		eventInteractive.propagateEvents = true;

		if ( spr != null ) {
			eventInteractive.width = spr.tile.width;
			eventInteractive.height = spr.tile.height;
		}
	}

	override function onAdd() {
		super.onAdd();
		onAdded.dispatch();
	}

	/**
		use when attached to an unrestrained parent or simple h2d.Object
	**/
	public function restraintSize() {
		minWidth = minHeight = maxWidth = maxHeight = defaultContainerSize;
		onAdded.add(() -> {
			minWidth = minHeight = maxWidth = maxHeight = null;
		}, true );
	}

	function updateTooltip() {
		if ( tooltip != null ) {
			tooltip.x = Boot.inst.s2d.mouseX + 25;
			tooltip.y = Boot.inst.s2d.mouseY + 25;
		}
	}

	public function changeAmount( v : Int ) {
		amountLabel.label = '${v}';
	}

	override function onRemove() {
		super.onRemove();
		if ( tooltip != null ) tooltip.remove();
	}
}
