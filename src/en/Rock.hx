package en;

class Rock extends Entity {
	public function new(x:Float, y:Float) {
		spr = new HSprite(Assets.tiles);

		spr.set("rock");
		super(x - 0.5, y-.7);
		// spr.setCenterRatio(0.5, 0.5);
	}

	// override function update() {
	// 	super.update();
		
	// }
}
