package game.client.render;

import h2d.RenderContext;
import util.Util;
import h2d.Object;
import dn.M;
import ch3.scene.TileSprite;
import dn.heaps.slib.HSprite;
import game.client.level.LevelView;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import shader.DepthOffset;
import util.Assets;

class Parallax extends Object {

	var spr : HSprite;

	// var tex : Texture;
	var cameraX = 0.;
	var cameraY = 0.;

	public var parallaxEffect = new Vector( .5, .5 );

	public function new( ?parent : Object ) {
		super( parent );
		
		spr = new HSprite( Assets.env );

		drawParallax();

		Main.inst.delayer.addF(() -> {
			if ( GameClient.inst != null ) @:privateAccess {
				cameraX = GameClient.inst.cameraProc.camera.targetOffset.x;
				cameraY = GameClient.inst.cameraProc.camera.targetOffset.y;
			}
		}, 2 );
		// mesh.scale( .5 );
		// mesh.alwaysSync = true;
	}

	public function drawParallax() {
		// tex.wrap = Repeat;

		// tex.filter = Nearest;
		for ( i in 0...5 ) {
			var tileGroup = new h2d.TileGroup( spr.tile, this);

			for ( i in 0...Std.int( Random.int( 100, 200 ) * Util.hScaled / 720 ) ) {
				spr.set( Assets.env, Random.fromArray( [
					"red_star_big",
					"blue_star_big",
					"yellow_star_big",
					"blue_star_small",
					"red_star_small",
					"yellow_star_small"
				] ) );
				tileGroup.add( Std.random( Util.wScaled ), Std.random( Util.hScaled ), spr.tile );
			}
			var tex = new Texture( Util.wScaled, Util.wScaled, [Target] );
		}

		// if ( mesh != null ) {
		// 	mesh.tile = Tile.fromTexture( tex );
		// 	mesh.tile = mesh.tile.center();
		// }
	}

	override function sync( ctx : RenderContext ) @:privateAccess {
		super.sync( ctx );
		if ( LevelView.inst != null && GameClient.inst != null ) {
			var deltaX = GameClient.inst.cameraProc.camera.targetOffset.x - cameraX;
			var deltaY = GameClient.inst.cameraProc.camera.targetOffset.y - cameraY;

			// mesh.tile.scrollDiscrete( deltaX * parallaxEffect.x, deltaY * parallaxEffect.y );
			// mesh.tile = mesh.tile;

			cameraX = GameClient.inst.cameraProc.camera.targetOffset.x;
			cameraY = GameClient.inst.cameraProc.camera.targetOffset.y;
		}
	}
}
