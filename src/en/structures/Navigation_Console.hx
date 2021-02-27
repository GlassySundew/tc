package en.structures;

import en.player.Player;
import hxd.Event;
import ui.Navigation;

class Navigation_Console extends Structure {
	var navigation : Navigation;
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, y, tmxObject, cdbEntry);
		navigation = new Navigation(Level.inst.game.root);
		ca = Main.inst.controller.createAccess("inventory");

		#if !headless
		interact.onTextInput = function(e : Event) {
			if ( ca.aPressed() ) {
				navigation.win.visible = true;
			}
		}
		#end
	}
	override function dispose() {
		super.dispose();
		navigation.destroy();
		
	}

	override function postUpdate() {
		super.postUpdate();
		if ( distPx(Player.inst) > Data.structures.get(cdbEntry).use_range && navigation != null ) navigation.win.visible = false;
	}
}
