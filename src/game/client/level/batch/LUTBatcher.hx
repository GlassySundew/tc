package game.client.level.batch;

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

	public function addMesh( path : String, lookup : Texture, lutRows : Int, x : Float, y : Float, z : Float, lutOffX : Int, lutOffY : Int ) {
		if ( batchMap[path] == null ) {
			batchMap[path] = new LUTBatch( path, lookup, lutRows );
		}
		batchMap[path].meshes.push(
			new LUTMesh(
				x,
				y,
				z,
				lutOffX,
				lutOffY
			)
		);
	}

	public function draw() {
		for ( batch in batchMap ) {
			batch.mb.begin( batch.meshes.length );

			for ( mesh in batch.meshes ) {
				batch.mb.x = mesh.x;
				batch.mb.y = mesh.y;
				batch.mb.z = mesh.z;
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
	public var lutShader : LUT;

	public inline function new( path : String, lookup : Texture, lutRows : Int ) {
		mb = new MeshBatch( cast( loadMesh( path ).primitive, HMDModel ), Boot.inst.s3d );
		lutShader = new LUT( lookup, lutRows );
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
	public var lutOffX : Int;
	public var lutOffY : Int;
	

	public inline function new( x, y, z, lutOffX, lutOffY ) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.lutOffX = lutOffX;
		this.lutOffY = lutOffY;
	}
}
