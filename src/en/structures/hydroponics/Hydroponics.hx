package en.structures.hydroponics;

import hxd.Event;
import en.items.Plant;
import en.objs.IsoTileSpr;
import h3d.Vector;
import format.tmx.Data.TmxObject;
import hxd.Key in K;

class Hydroponics extends Interactive {
	public var plantContainer:Plant;

	public function new(?x:Float = 0, ?z:Float = 0, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.anim.registerStateAnim("hydroponics0", 0, 1, function() return plantContainer == null);
			spr.anim.registerStateAnim("hydroponics1", 0, 1, function() return plantContainer != null);
		}
		super(x, z, tmxObj);
		interactable = true;
		mesh.isLong = true;
		mesh.isoWidth = 2;
		mesh.isoHeight = 1;
		mesh.renewDebugPts();
		plantContainer = new Plant(0, 0); 
		interact.onTextInput = function(e:Event) {
			if (K.isPressed(K.E))
				inline dropGrownPlant();
		}
	}

	function dropGrownPlant() {
		if (plantContainer != null) {
			interactable = false;
			new FloatingItem(mesh.x + 1, mesh.z - 1, plantContainer).bumpAwayFrom(this, .05);
			plantContainer = null;
		}
	}
}
