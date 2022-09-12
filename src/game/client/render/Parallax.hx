package game.client.render;

import shader.VoxelDepther;
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

	// var tex : Texture;
	var cameraX = 0.;
	var cameraY = 0.;

	public var parallaxEffect = new Vector( .5, .5 );

	var skyTexture : Texture;

	public function new( ?parent : Object ) {
		super( parent );
		spr = new HSprite( Assets.env );

		skyTexture = new Texture( 128, 128, [Cube, Target, MipMapped] );
		skyTexture.filter = Nearest;
		drawParallax();
		var sky = new h3d.prim.Sphere( 30, 128, 128 );
		sky.addNormals();
		var skyMesh = new h3d.scene.Mesh( sky ); // todo
		skyMesh.rotate( 0, M.toRad( 45 ), 0 );

		skyMesh.material.mainPass.culling = Front;
		skyMesh.material.mainPass.addShader( new h3d.shader.CubeMap( skyTexture ) );
		skyMesh.material.shadows = false;
		skyMesh.material.mainPass.enableLights = false;
		skyTexture.mipMap = Linear;

		skyMesh.scale( 20 );

		// mesh = new TileSprite( Tile.fromTexture( tex ), 1, true, this );
		// mesh.material.blendMode = Alpha;
		// mesh.tile = mesh.tile.center();
		// mesh.material.mainPass.addShader( new VoxelDepther( -0.5 ) );
		// mesh.material.mainPass.depth( false, LessEqual );

		Main.inst.delayer.addF(() -> {
			if ( GameClient.inst != null ) {
				cameraX = GameClient.inst.camera.x;
				cameraY = GameClient.inst.camera.y;
			}
		}, 2 );
		// mesh.scale( .5 );
		// mesh.alwaysSync = true;
	}

	public function drawParallax() {
		// tex.wrap = Repeat;
		skyTexture.clear( 0 );

		// tex.filter = Nearest;
		for ( i in 0...5 ) {
			var tileGroup = new h2d.TileGroup( spr.tile );

			for ( i in 0...Std.int( Random.int( 100, 200 ) * skyTexture.height / 720 ) ) {
				spr.set( Assets.env, Random.fromArray( [
					"red_star_big",
					"blue_star_big",
					"yellow_star_big",
					"blue_star_small",
					"red_star_small",
					"yellow_star_small"
				] ) );
				tileGroup.add( Std.random( skyTexture.width ), Std.random( skyTexture.height ), spr.tile );
			}
			var tex = new Texture( skyTexture.width, skyTexture.width, [Target] );

			tileGroup.drawTo( tex );
			skyTexture.uploadPixels( tex.capturePixels(), 0, i );
		}

		// if ( mesh != null ) {
		// 	mesh.tile = Tile.fromTexture( tex );
		// 	mesh.tile = mesh.tile.center();
		// }
	}

	override function sync( ctx : RenderContext ) {
		super.sync( ctx );
		if ( Level.inst != null && GameClient.inst != null ) {
			var deltaX = GameClient.inst.camera.x - cameraX;
			var deltaY = GameClient.inst.camera.y - cameraY;

			// mesh.tile.scrollDiscrete( deltaX * parallaxEffect.x, deltaY * parallaxEffect.y );
			// mesh.tile = mesh.tile;

			cameraX = GameClient.inst.camera.x;
			cameraY = GameClient.inst.camera.y;
		}
	}
}
