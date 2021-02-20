package en.structures;

import hxd.Key;
import hxd.Event;
import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Door extends Structure {
	public var leadsTo : String;

	public function new(?x : Int = 0, ?z : Int = 0, ?tmxObj : TmxObject, ?cdbEntry : StructuresKind) {
		super(x, z, tmxObj, cdbEntry);

		if ( tmxObj != null && tmxObj.properties.exists("to") ) leadsTo = tmxObj.properties.getString("to");

		interact.onTextInputEvent.add((e : Event) -> {
			if ( Key.isPressed(Key.E) ) {
				turnOffHighlight();

				if ( leadsTo != null ) {
					var castedG = cast(Level.inst.game, Game);
					var curLvl = castedG.lvlName;
					castedG.startLevel(leadsTo);
					var door = findDoor(curLvl);
					if ( door != null ) {
						player.setFeetPos(door.footX, door.footY);
						castedG.camera.recenter();
					}
				}
			}
		});
	}

	function findDoor(to : String) : Entity {
		for (e in Entity.ALL) {
			if ( e.isOfType(en.structures.Door)
				&& e.tmxObj.properties.exists("to")
				&& e.tmxObj.properties.getFile("to").split(".")[0] == to ) {
				return e;
			}
		}
		#if debug
		throw "wrong door markup";
		#end
		return null;
	}

	override function postUpdate() {
		super.postUpdate();

		// mesh.z += 1 / Camera.ppu;
	}
}
