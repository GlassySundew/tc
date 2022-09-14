package game.client.level.batch;

import shader.DepthOffset;
import h3d.scene.Object;
import h3d.mat.Texture;
import shader.LUT;
import h3d.prim.HMDModel;
import utils.Assets;
import hxd.Res;
import h3d.scene.Mesh;
import h3d.scene.MeshBatch;

class LUTBatcher {

	var batchMap : Map<String, LUTBatch> = [];

	public function new() {}

	public function addMesh(
		path : String,
		lookup : Texture,
		lutRows : Int,
		x : Float,
		y : Float,
		z : Float,
		lutOffX : Int,
		lutOffY : Int,
		depthOffset : Float,
		?parent : Object
	) {
		if ( batchMap[path] == null ) {
			batchMap[path] = new LUTBatch( path, lookup, lutRows, parent );
		}
		batchMap[path].meshes.push(
			new LUTMesh(
				x,
				y,
				z,
				depthOffset,
				lutOffX,
				lutOffY
			)
		);
	}

	public function emitAll() {
		for ( batch in batchMap ) {
			batch.mb.begin( batch.meshes.length );

			for ( mesh in batch.meshes ) {
				batch.mb.x = mesh.x;
				batch.mb.y = mesh.y;
				batch.mb.z = mesh.z;
				batch.depthOffsetShader.offset = mesh.depthOffset;
				batch.lutShader.offsetX = mesh.lutOffX;
				batch.lutShader.offsetY = mesh.lutOffY;
				batch.mb.emitInstance();
			}
		}
	}
}

class LUTBatch {

	public var mb : MeshBatch;
	public var meshes : Array<LUTMesh> = [];
	public var depthOffsetShader : DepthOffset;
	public var lutShader : LUT;

	public inline function new( path : String, lookup : Texture, lutRows : Int, ?parent : Object ) {
		var mesh = loadMesh( path );
		mb = new MeshBatch( cast( mesh.primitive, HMDModel ), parent );
		mb.material.shadows = false;
		mb.material.texture = mesh.material.texture;
		mb.material.texture.filter = Nearest;

		lutShader = new LUT( lookup, lutRows );
		depthOffsetShader = new DepthOffset( 0 );
		mb.material.mainPass.addShader( lutShader );
		mb.material.mainPass.addShader( depthOffsetShader );
	}

	inline function loadMesh( path : String ) : Mesh {
		if ( !Res.loader.exists( path ) ) throw "model does not exists on path: " + path;
		return cast( Assets.modelCache.loadModel( Res.loader.load( path ).toModel() ), Mesh );
	}
}

class LUTMesh {

	public var x : Float;
	public var y : Float;
	public var z : Float;
	public var depthOffset : Float;
	public var lutOffX : Int;
	public var lutOffY : Int;

	public inline function new( x, y, z, depthOffset : Float, lutOffX, lutOffY ) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.depthOffset = depthOffset;
		this.lutOffX = lutOffX;
		this.lutOffY = lutOffY;
	}
}
