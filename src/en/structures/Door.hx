package en.structures;

import hxd.Key;
import hxd.Event;
import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;

class Door extends Interactive {
	public var leadsTo: String;

	public function new(?x: Float = 0, ?z: Float = 0, ?tmxObj: TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures, entParent);
			spr.set("door");
		}
		super(x, z, tmxObj);
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
					var curLvl = game.lvlName;
					game.startLevel(leadsTo + ".tmx");
					var door = findDoor(curLvl);
					player.setFeetPos(door.footX, door.footY);
					game.camera.recenter();
				}
			}
		});
	}

	function findDoor(to: String): Entity {
		for (e in Entity.ALL) {
			if (Std.is(e, Door) && e.tmxObj.properties.exists("to") && e.tmxObj.properties.getString("to") == to) {
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
