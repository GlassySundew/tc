package en.structures;

import hxd.Event;
import en.player.Player;
import ui.player.Crafting;
import format.tmx.Data.TmxObject;

class Workbench extends Structure {
	var crafting : Crafting;

	var ca : ControllerAccess<ControllerAction>;

	public function new( x : Float, y : Float, ?tmxObject : TmxObject ) {
		super(x, y, tmxObject);
		interactable = true;
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
		ca = Main.inst.controller.createAccess();

		GameClient.inst.delayer.addF(() -> {

			crafting = new Crafting(Workbench, Player.inst.ui.root);
			crafting.recenter();
		}, 2);

		interact.onTextInputEvent.add(( e : Event ) -> {
			if ( ca.isPressed(Escape) ) {
				if ( !Player.inst.ui.inventory.win.visible ) Player.inst.ui.inventory.toggleVisible();
				crafting.toggleVisible();
				// Window.centrizeTwoWins(Player.inst.ui.inventory, inventory);
			}
		});
	}
}
