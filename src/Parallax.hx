import h3d.Vector;
import h3d.scene.RenderContext;
import h2d.Tile;
import dn.RandList;
import h3d.mat.Texture;
import ch3.scene.TileSprite;
import h3d.scene.Object;

class Parallax extends Object {
	var drawer : HSprite;

	public var mesh : TileSprite;

	var tex : Texture;

	var cameraX = 0.;
	var cameraY = 0.;

	public var parallaxEffect = new Vector(.5, .5);

	public function new( ?parent : Object ) {
		super(parent);
		drawer = new HSprite(Assets.env);

		drawParallax();

		mesh = new TileSprite(Tile.fromTexture(tex), 1, false, this);
		mesh.rotate(0, 0, M.toRad(90));
		mesh.material.blendMode = Alpha;
		mesh.tile = mesh.tile.center();

		mesh.material.mainPass.depth(false, LessEqual);

		Main.inst.delayer.addF(() -> {
			if ( Game.inst != null ) {
				cameraX = Game.inst.camera.x;
				cameraY = Game.inst.camera.y;
			}
		}, 2);
		mesh.scale(.5);
		mesh.alwaysSync = true;
	}

	public function drawParallax() {
		tex = new Texture(Main.inst.w(), Main.inst.h(), [Target]);
		tex.wrap = Repeat;

		tex.filter = Nearest;
		var tileGroup = new h2d.TileGroup(drawer.tile);

		for ( i in 0...Std.int(Random.int(100, 200) * Main.inst.h() / 720) ) {
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

		if ( mesh != null ) {
			mesh.tile = Tile.fromTexture(tex);
			mesh.tile = mesh.tile.center();
		}
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		if ( Level.inst != null && Level.inst.game != null ) {
			var deltaX = Level.inst.game.camera.x - cameraX;
			var deltaY = Level.inst.game.camera.y - cameraY;

			mesh.tile.scrollDiscrete(deltaX * parallaxEffect.x, deltaY * parallaxEffect.y);
			mesh.tile = mesh.tile;

			cameraX = Level.inst.game.camera.x;
			cameraY = Level.inst.game.camera.y;
		}
	}
}
