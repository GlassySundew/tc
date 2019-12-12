package en;

class Rock extends Entity {
	public function new(x:Float, y:Float) {
		spr = new HSprite(Assets.tiles);

		spr.set("rock");
		// super(x - 0.5, y - 5 / 8);
		super(x, y);
		sprOffY = -.75;
		sprOffX = -.5;

		sprOffCollY = 0.3;
		// spr.setCenterRatio(0.5, 0.5);
	}
	// override function update() {
	// 	super.update();
	// }
}
