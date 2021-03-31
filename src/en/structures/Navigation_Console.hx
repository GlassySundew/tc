package en.structures;

import format.tmx.Data.TmxObject;
import en.player.Player;
import hxd.Event;
import ui.Navigation;

class Navigation_Console extends Structure {
	var navigation : Navigation;
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, y, tmxObject, cdbEntry);
	}

	public override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		super.init(x, z, tmxObj);
		#if !headless
		navigation = new Navigation(Level.inst.game.root);
		ca = Main.inst.controller.createAccess("inventory");
		interact.onTextInput = function(e : Event) {
			if ( ca.aPressed() ) {
				navigation.win.visible = true;
			}
		}
		#end
	}

	override function dispose() {
		#if !headless
		if ( navigation != null ) navigation.destroy();
		#end
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
		#if !headless
		if ( Player.inst != null
			&& distPx(Player.inst) > Data.structures.get(cdbEntry).use_range
			&& navigation != null ) navigation.win.visible = false;
		#end
	}
}
