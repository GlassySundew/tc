package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;
import hxd.Event;
import ui.Navigation;

class NavigationConsole extends Structure {
	var navigation : Navigation;
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new( x : Float, y : Float, ?tmxObject : TmxObject, ?cdbEntry : Data.StructuresKind ) {
		super(x, y, tmxObject, cdbEntry);
		interactable = true;
	}

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);

		#if !headless
		Game.inst.delayer.addF(() -> {
			navigation = if ( Navigation.inst != null ) {
				Player.inst.ui.root.addChild(Navigation.inst.win);
				Navigation.inst;
			} else {
				new Navigation(
					Const.jumpReach,
					'${Game.inst.seed}',
					Player.inst.ui.root
				);
			}

			Navigation.inst.updateBackgroundInteractive();

			ca = Main.inst.controller.createAccess("navigation");
			interact.onTextInput = function ( e : Event ) {
				if ( ca.aPressed() ) {
					navigation.toggleVisible();
				}
			}
		}, 2);
		#end
	}

	@:keep
	override function customSerialize( ctx : Serializer ) {
		super.customSerialize(ctx);
	}

	@:keep
	override function customUnserialize( ctx : Serializer ) {
		super.customUnserialize(ctx);
	}

	override function dispose() {
		#if !headless
		if ( navigation != null ) {
			navigation.win.remove();
			navigation.flushHeads();
		}
		#end
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
		#if !headless
		if ( navigation != null
			&& navigation.win.visible
			&& Player.inst != null
			&& Player.inst.isMoving()
			&& distPx(Player.inst) > useRange
			&& navigation != null ) navigation.toggleVisible();
		#end
	}
}
