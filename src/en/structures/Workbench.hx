package en.structures;

import dn.heaps.input.ControllerAccess;
import game.client.GameClient;
import game.client.ControllerAction;
import hxd.Event;
import en.player.Player;
import ui.player.Crafting;
import format.tmx.Data.TmxObject;

class Workbench extends Structure {

	var crafting : Crafting;

	var ca : ControllerAccess<ControllerAction>;

	public function new( ?tmxObject : TmxObject ) {
		super( tmxObject );
		canBeInteractedWith.val = true;
	}

	override function init() {
		super.init();
		ca = Main.inst.controller.createAccess();

		GameClient.inst.delayer.addF(() -> {
			crafting = new Crafting( Workbench, GameClient.inst.root );
			crafting.recenter();
		}, 2 );

		interact.onTextInputEvent.add( ( e : Event ) -> {
			if ( ca.isPressed( Escape ) ) {
				if ( !Player.inst.pui.inventory.win.visible ) Player.inst.pui.inventory.toggleVisible();
				crafting.toggleVisible();
				// Window.centrizeTwoWins(Player.inst.pui.inventory, inventory);
			}
		} );
	}
}
