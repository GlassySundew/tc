import h3d.Vector;
import h3d.scene.RenderContext;
import h2d.Tile;
import dn.RandList;
import h3d.mat.Texture;
import ch3.scene.TileSprite;
import h3d.scene.Object;

class Parallax extends Object {
	var drawer : HSprite;
	var mesh : TileSprite;
	var tex : Texture;

	var cameraX = 0.;
	var cameraY = 0.;

	public var parallaxEffect = new Vector(.5, .5);

	public function new(?parent : Object) {
		super(parent);
		drawer = new HSprite(Assets.env);
		drawParallax();

		mesh = new TileSprite(Tile.fromTexture(tex), 1, false, this);
		mesh.rotate(0, 0, M.toRad(90));
		mesh.material.blendMode = Alpha;

		mesh.material.mainPass.depth(false, Less);

		Main.inst.delayer.addF(() -> {
			cameraX = Game.inst.camera.x;
			cameraY = Game.inst.camera.y;
		}, 1);
		mesh.scale(.5);
	}

	function drawParallax() {
		tex = new Texture(Main.inst.w(), Main.inst.h(), [Target]);
		tex.filter = Nearest;
		var tileGroup = new h2d.TileGroup(drawer.tile);

		for (i in 0...Random.int(200, 300)) {
			drawer.set(Assets.env, Random.fromArray([
				"red_star_big",
				"blue_star_big",
				"yellow_star_big",
				"blue_star_small",
				"red_star_small",
				"yellow_star_small"
			]));
			tileGroup.add(Std.random(Main.inst.w()), Std.random(Main.inst.h()), drawer.tile);
		}
		tileGroup.drawTo(tex);
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);

		// var deltaX = Game.inst.camera.x - cameraX;
		// var deltaY = Game.inst.camera.x - cameraY;

		// @:privateAccess {
		// 	mesh.tile.u += deltaX * parallaxEffect.x;
		// 	mesh.tile.v += deltaY * parallaxEffect.y;
		// }
	}
}
