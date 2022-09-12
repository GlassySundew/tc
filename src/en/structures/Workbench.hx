package en.structures;

import game.client.GameClient;
import game.client.ControllerAction;
import hxd.Event;
import en.player.Player;
import ui.player.Crafting;
import format.tmx.Data.TmxObject;

class Workbench extends Structure {

	var crafting : Crafting;

	var ca : ControllerAccess<ControllerAction>;

	public function new( x = 0., y = 0., z = 0., ?tmxObject : TmxObject ) {
		super( x, y, z, tmxObject );
		interactable = true;
	}

	override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super.init( x, y, z, tmxObj );
		ca = Main.inst.controller.createAccess();

		GameClient.inst.delayer.addF(() -> {

			crafting = new Crafting( Workbench, Player.inst.pui.root );
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
