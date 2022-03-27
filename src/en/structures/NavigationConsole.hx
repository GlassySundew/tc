package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;
import hxd.Event;
import ui.Navigation;

class NavigationConsole extends Structure {
	var navigation : NavigationWindow;
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new( x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : Data.StructureKind ) {
		super(x, y, tmxObject, cdbEntry);
		interactable = true;
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
	}

	override function alive() {
		super.alive();

		GameClient.inst.delayer.addF(() -> {
			navigation = if ( Navigation.clientInst.navWin == null ) {
				Navigation.clientInst.navWin = new NavigationWindow(
					Const.jumpReach,
					Client.inst.seed,
					Player.inst.ui.root
				);
			} else {
				Player.inst.ui.root.addChild(Navigation.clientInst.navWin.win);
				Navigation.clientInst.navWin;
			}

			if ( Navigation.clientInst != null ) {
				Player.inst.ui.root.addChild(Navigation.clientInst.navWin.win);
				Navigation.clientInst;
			} else {
				new NavigationWindow(
					Const.jumpReach,
					Client.inst.seed,
					Player.inst.ui.root
				);
			}

			Navigation.clientInst.navWin.updateBackgroundInteractive();

			ca = Main.inst.controller.createAccess("navigation");
			interact.onTextInput = function ( e : Event ) {
				if ( ca.aPressed() ) {
					navigation.toggleVisible();
				}
			}
		}, 2);
	}

	// @:keep
	// override function customSerialize( ctx : Serializer ) {
	// 	super.customSerialize(ctx);
	// }

	// @:keep
	// override function customUnserialize( ctx : Serializer ) {
	// 	super.customUnserialize(ctx);
	// }

	override function dispose() {
		if ( navigation != null ) {
			navigation.win.remove();
			navigation.flushHeads();
		}
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
		if ( navigation != null
			&& navigation.win.visible
			&& Player.inst != null
			&& Player.inst.isMoving
			&& distPx(Player.inst) > useRange
			&& navigation != null ) navigation.toggleVisible();
	}
}
