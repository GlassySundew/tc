package ent;

class Block extends Entity {
	public function new(posi, x, y) {
		super(posi, x, y);
	}

	override function getAnim() {
		return [hxd.Res.templarcell.toTile()];
	}

	override function update(dt:Float) {
		super.update(dt);
	}
}
