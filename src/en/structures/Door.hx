package en.structures;

import hxd.Key;
import hxd.Event;
import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Door extends Structure {
	public var leadsTo: String;

	public function new(?x: Int = 0, ?z: Int = 0, ?tmxObj: TmxObject , ?cdbEntry : StructuresKind) {
		if (spr == null) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("door");
		}
		super(x, z, tmxObj , cdbEntry );
		interactable = true;

		mesh.isLong = true;
		mesh.isoWidth = 1.3;
		mesh.isoHeight = 0.4;
		mesh.renewDebugPts();

		if (tmxObj.properties.exists("to")) leadsTo = tmxObj.properties.getString("to");

		interact.onTextInputEvent.add((e: Event) -> {
			if (Key.isPressed(Key.E)) {
				turnOffHighlight();

				if (leadsTo != null) {
					var castedG = cast(game, Game);
					var curLvl = castedG.lvlName;
					castedG.startLevel(leadsTo + ".tmx");
					var door = findDoor(curLvl);
					player.setFeetPos(door.footX, door.footY);
					castedG.camera.recenter();
				}
			}
		});
	}

	function findDoor(to: String): Entity {
		for (e in Entity.ALL) {
			if (e.isOfType(en.structures.Door) && e.tmxObj.properties.exists("to") && e.tmxObj.properties.getString("to") == to) {
				return e;
			}
		}
		throw "wrong door markup";
	}

	override function postUpdate() {
		super.postUpdate();

		// mesh.z += 1 / Camera.ppu;
	}
}
