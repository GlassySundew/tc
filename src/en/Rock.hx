package en;

class Rock extends Entity {
	public function new(?x:Float = 0, ?z:Float = 0) {
		if (spr == null)
			spr = new HSprite(Assets.tiles);

		spr.set("rock");
		// super(x - 0.5, y - 5 / 8);
		super(x, z);

		bottomAlpha = 11;

		sprOffY = -.18;
		sprOffX = -.5;

		// mesh.originMX = 24 / 46;
		// mesh.originMY = 14 / 27;
	}

	override function postUpdate() {
		super.postUpdate();
		// mesh.z += 1 / Camera.ppu;
	}

	// override function update() {
	// 	super.update();
	// }
}
