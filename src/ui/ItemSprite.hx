package ui;

import haxe.CallStack;
import ch2.ui.EventInteractive;
import en.player.Player;
import h2d.Flow;
import h2d.Object;
import hxd.Key;
import ui.domkit.TextLabelComp;

/**
	ui обёртка над en.Item
**/
class ItemSprite extends Flow {
	public var spr : HSprite;
	public var eventInteractive : EventInteractive;
	public var amountLabel : TextLabelComp;
	public var item : Item;

	var tooltip : TextLabelComp;
	var ca : dn.heaps.Controller.ControllerAccess;

	var displayText : String = "";

	public function new( item : Item, ?parent : h2d.Object ) {
		super(parent);
		
		ca = Main.inst.controller.createAccess("chest");

		this.item = item;
		item.itemSprite = this;

		horizontalAlign = Middle;
		verticalAlign = Middle;

		spr = new HSprite(Assets.items, this);
		if ( item.cdbEntry != null ) {
			spr.set(Data.item.get(item.cdbEntry).atlas_name);
			displayText = Data.item.get(item.cdbEntry).display_name;
		}

		spr.tile.getTexture().filter = Nearest;

		fillHeight = fillWidth = true;

		amountLabel = new TextLabelComp('${item.amount}', Assets.fontPixel, this);
		amountLabel.scale(.5);

		amountLabel.dom.setAttribute("position", VIdent("absolute"));
		amountLabel.dom.setAttribute("valign", VIdent("bottom"));
		amountLabel.dom.setAttribute("halign", VIdent("right"));
		amountLabel.dom.setAttribute("padding", VInt(1));
		amountLabel.dom.setAttribute("padding-bottom", VInt(0));
		amountLabel.dom.setAttribute("padding-top", VInt(0));
		amountLabel.dom.setAttribute("padding-right", VInt(2));
		amountLabel.labelTxt.dom.setAttribute("offset-y", VInt(-3));
		amountLabel.forceDecrHeight = 4;
		amountLabel.cornersRounder.radius = 6;
		amountLabel.cornersRounder.edgeSoftness = 1;

		eventInteractive = new EventInteractive(spr.tile.width, spr.tile.height, spr);
		eventInteractive.enableRightButton = true;

		eventInteractive.onOver = function ( e : hxd.Event ) {
			tooltip = new TextLabelComp(displayText, Assets.fontPixel, Boot.inst.s2d);
			updateTooltip();
		}

		eventInteractive.onMove = function ( e ) {
			updateTooltip();
		}

		eventInteractive.onOut = function ( e : hxd.Event ) {
			tooltip.remove();
		}

		eventInteractive.onFocusEvent.add(function ( e : hxd.Event ) {});

		eventInteractive.onPush = ( e ) -> {
			tooltip.remove();
		}

		eventInteractive.onTextInput = ( e ) -> {
			if ( ca.yPressed() ) {
				if ( !item.isDisposed ) {
					if ( Key.isDown(Key.CTRL) ) {
						// dropping whole stack
						Player.inst.dropItem(Item.fromCdbEntry(item.cdbEntry, Player.inst, item.amount), Player.inst.angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
						item.amount = 0;
					} else {
						// dropping 1 item
						item.amount--;
						Player.inst.dropItem(Item.fromCdbEntry(item.cdbEntry, Player.inst, 1), Player.inst.angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
					}
				}
			}
		}

		eventInteractive.propagateEvents = true;

		if ( spr != null ) {

			eventInteractive.width = spr.tile.width;
			eventInteractive.height = spr.tile.height;
		}
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
