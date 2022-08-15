package game.test;

import h3d.scene.fwd.LightSystem;
import h2d.Bitmap;
import h3d.scene.Mesh;
import hxd.Res;
import shader.LUT;
import utils.Assets;

class VoxelSceneTest {

	public static function start() @:privateAccess {
		Boot.inst.engine.backgroundColor = 0xB6ADAD;

		var lut = new LUT( Assets.CONGRUENT.texture, 4 );
		// wholeLutTest();
		meshTest();
		// bmpTest( lut );
	}

	static function bmpTest( lut : LUT ) {
		var bitmap = new Bitmap( Res.lut8.toTile(), Boot.inst.s2d );
		Boot.inst.s2d.addEventListener(
			( e ) -> {
				switch( e.kind ) {
					case EWheel:
						bitmap.scaleX += e.wheelDelta;
						bitmap.scaleY += e.wheelDelta;
					default:
				}
			}
		);
		bitmap.addShader( lut );
	}

	static function wholeLutTest() {
		var cache = new utils.s3d.ModelCache();
		cache.loadLibrary( Res.tiled.voxel.CONGRUENT.box );
		var obj = cast( cache.loadModel( Res.tiled.voxel.CONGRUENT.box ), Mesh );
		obj.material.texture.filter = Nearest;
		obj.material.shadows = false;
		// obj.material.li shadows = false;

		obj.material.mainPass.addShader( new LUT( Assets.CONGRUENT.texture, 4 ) );

		Boot.inst.s3d.addChild( obj );
		var cam = new h3d.scene.CameraController( 20, Boot.inst.s3d );
		cam.loadFromCamera();
	}

	static function meshTest() {
		var cache = new utils.s3d.ModelCache();
		var cam = new h3d.scene.CameraController( 20, Boot.inst.s3d );
		cam.loadFromCamera();

		// var ls = cast( Boot.inst.s3d.lightSystem, LightSystem );
		// ls.ambientLight.x = ;

		function spawnBlock( blockAppend : String, blockX : Int, blockY : Int, doLut = true, lutOffX : Int, lutOffY : Int ) {
			if ( !Res.loader.exists( "tiled/voxel/CONGRUENT/block_" + blockAppend + ".fbx" ) ) return;

			var obj = cast( cache.loadModel( cast Res.loader.load( "tiled/voxel/CONGRUENT/block_" + blockAppend + ".fbx" ).toModel() ), Mesh );
			if ( obj.material.texture != null )
				obj.material.texture.filter = Nearest;
			obj.material.shadows = false;

			if ( doLut ) {
				obj.material.mainPass.addShader( new LUT( Assets.CONGRUENT.texture, 4, lutOffX, lutOffY ) );
			}
			Boot.inst.s3d.addChild( obj );

			// obj.lightCameraCenter = true;

			obj.x = blockX;
			obj.y = blockY;
		}

		var cngrnt = Assets.CONGRUENT;

		for ( ifig => fig in Assets.CONGRUENT.figures ) {
			for ( ipal in 0...fig.palettes ) {
				spawnBlock(
					'${ifig}',
					ifig * 10,
					ipal * 10,
					true,
					( fig.figStartX ) * cngrnt.tileW,
					( fig.figStartY + ipal ) * cngrnt.tileH
				);
			}
		}
	}
}
