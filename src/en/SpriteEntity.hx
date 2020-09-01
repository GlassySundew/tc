package en;

import format.tmx.Data.TmxObject;

class SpriteEntity extends Interactive {
	public function new(?x:Float = 0, ?z:Float = 0, sprite:String, ?tmxObj:TmxObject) {
		if (spr == null) {
			spr = new HSprite(Assets.structures);
			spr.set(sprite);
		}

		super(x, z, tmxObj);
		if (tmxObj.properties.exists("interactable"))
			interactable = tmxObj.properties.getBool("interactable");
	}
}
