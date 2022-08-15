package game.client.render;

import game.client.level.Level;
import ch3.scene.TileSprite;
import dn.heaps.slib.HSprite;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import h3d.scene.Object;
import h3d.scene.RenderContext;
import utils.Assets;

class Parallax extends Object {

	var spr : HSprite;

	public var mesh : TileSprite;

	var tex : Texture;

	var cameraX = 0.;
	var cameraY = 0.;

	public var parallaxEffect = new Vector( .5, .5 );

	public function new( ?parent : Object ) {
		super( parent );
		spr = new HSprite( Assets.env );

		drawParallax();

		mesh = new TileSprite( Tile.fromTexture( tex ), 1, false, this );
		mesh.rotate( 0, 0, M.toRad( 90 ) );
		mesh.material.blendMode = Alpha;
		mesh.tile = mesh.tile.center();

		mesh.material.mainPass.depth( false, LessEqual );

		Main.inst.delayer.addF(() -> {
			if ( GameClient.inst != null ) {
				cameraX = GameClient.inst.camera.x;
				cameraY = GameClient.inst.camera.y;
			}
		}, 2 );
		mesh.scale( .5 );
		mesh.alwaysSync = true;
	}

	public function drawParallax() {
		tex = new Texture( Main.inst.w(), Main.inst.h(), [Target] );
		tex.wrap = Repeat;

		tex.filter = Nearest;
		var tileGroup = new h2d.TileGroup( spr.tile );

		for ( i in 0...Std.int( Random.int( 100, 200 ) * Main.inst.h() / 720 ) ) {
			spr.set( Assets.env, Random.fromArray( [
				"red_star_big",
				"blue_star_big",
				"yellow_star_big",
				"blue_star_small",
				"red_star_small",
				"yellow_star_small"
			] ) );
			tileGroup.add( Std.random( Main.inst.w() ), Std.random( Main.inst.h() ), spr.tile );
		}
		tileGroup.drawTo( tex );

		if ( mesh != null ) {
			mesh.tile = Tile.fromTexture( tex );
			mesh.tile = mesh.tile.center();
		}
	}

	override function sync( ctx : RenderContext ) {
		super.sync( ctx );
		if ( Level.inst != null && GameClient.inst != null ) {
			var deltaX = GameClient.inst.camera.x - cameraX;
			var deltaY = GameClient.inst.camera.y - cameraY;

			mesh.tile.scrollDiscrete( deltaX * parallaxEffect.x, deltaY * parallaxEffect.y );
			mesh.tile = mesh.tile;

			cameraX = GameClient.inst.camera.x;
			cameraY = GameClient.inst.camera.y;
		}
	}
}
