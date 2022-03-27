package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;
import hxd.Event;
import hxd.Key;

class Door extends Structure {
	@:s public var leadsTo : String;

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init(x, z, tmxObj);
		if ( tmxObj != null && tmxObj.properties.exists("to") )
			leadsTo = tmxObj.properties.getString("to");
	}

	override function alive() {
		super.alive();
		GameClient.inst.delayer.addF(() -> {
			interactable = true;
		}, 10);

		interact.onTextInputEvent.add(( e : Event ) -> {
			if ( Key.isPressed(Key.E) ) {
				turnOffHighlight();

				if ( leadsTo != null ) {
					var curLvl = GameClient.inst.sLevel.lvlName;

					// GameClient.inst.startLevel(leadsTo, {});
					GameClient.inst.delayer.addF(() -> {
						var door = findDoor(curLvl);
						if ( door != null ) {
							interactable = true;
							Player.inst.setFeetPos(door.footX, door.footY);
							GameClient.inst.targetCameraOnPlayer();
						}
					}, 1);
				}
			}
		});
	}

	// @:keep
	// override function customSerialize(ctx : Serializer) {
	// 	super.customSerialize(ctx);
	// }
	// @:keep
	// override function customUnserialize(ctx : Serializer) {
	// 	super.customUnserialize(ctx);
	// }

	function findDoor( to : String ) : Entity {
		for ( e in Entity.ALL ) {
			if ( e.isOfType(en.structures.Door) ) {
				if ( e.tmxObj != null && e.tmxObj.properties.exists("to") && e.tmxObj.properties.getFile("to").split(".")[0] == to ) {
					return e;
				}
			}
		}
		#if debug
		trace("wrong door logic???");
		
		// throw "wrong door markup";
		#end
		return null;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
