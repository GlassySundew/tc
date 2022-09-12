package utils.oimo;

import dn.Process;
import oimo.dynamics.rigidbody.RigidBodyType;
import hxd.IndexBuffer;
import h3d.col.Point;
import h3d.prim.Polygon;
import oimo.collision.geometry.ConvexHullGeometry;
import h3d.prim.Cube;
import h3d.scene.Mesh;
import oimo.collision.geometry.BoxGeometry;
import oimo.collision.geometry.GeometryType;
import oimo.dynamics.World;
import oimo.dynamics.rigidbody.RigidBody;
import oimo.dynamics.rigidbody.Shape;

class OimoDebugRenderer extends Process {

	var meshes : Map<Shape, Mesh> = [];

	public function new( parent : Process ) {
		super( parent );
	}

	public function initWorld( w : World ) {
		var rigidBody = w.getRigidBodyList();
		drawRBList( rigidBody );
		return this;
	}

	override function postUpdate() {
		super.postUpdate();
		for ( shape => mesh in meshes ) {
			syncShape( shape );
		}
	}

	inline function syncShape( shape : Shape ) {
		var mesh = meshes[shape];
		mesh.x = shape._rigidBody._transform._positionX + shape._localTransform._positionX;
		mesh.y = shape._rigidBody._transform._positionY + shape._localTransform._positionY;
		mesh.z = shape._rigidBody._transform._positionZ + shape._localTransform._positionZ;
		var transform = shape._rigidBody._transform;
		var eulerAngle = rotMatToEuler(
			transform._rotation00,
			transform._rotation10,
			transform._rotation20,
			transform._rotation21,
			transform._rotation22
		);

		mesh.setRotation( eulerAngle.x, eulerAngle.y, eulerAngle.z );
	}

	public function registerEntity( ent : Entity ) {
		drawRBList( ent.rigidBody, 0x1C4F4FC7 );
	}

	function drawRBList( rbList : RigidBody, color = 0x3F8CCE5D ) {
		while( rbList != null ) {
			var shape = rbList.getShapeList();
			while( shape != null ) {
				var mesh : Mesh = null;
				switch( shape.getGeometry().getType() ) {
					case GeometryType._BOX:
						var box = cast( shape.getGeometry(), BoxGeometry );
						var boxDim = box.getHalfExtents();
						var cube = new Cube( boxDim.x * 2, boxDim.y * 2, boxDim.z * 2 );
						cube.unindex();
						cube.addNormals();
						cube.translate(-boxDim.x, -boxDim.y, -boxDim.z );

						mesh = new Mesh( cube, Boot.inst.s3d );
						var rigidTransform = rbList.getTransform();
						mesh.x = rigidTransform._positionX;
						mesh.y = rigidTransform._positionY;
						mesh.z = rigidTransform._positionZ;
						mesh.material.mainPass.wireframe = true;
						mesh.material.color = Color.intToVector( color );
						mesh.material.shadows = false;

					case GeometryType._CONVEX_HULL:
						// всегда представляет собой вытянутый в высоту двумерный полигон
						var shapeGeom = cast( shape.getGeometry(), ConvexHullGeometry );
						var verts = shapeGeom.getVertices();

						var hpsPts : Array<Point> = [];
						for ( vert in verts ) hpsPts.push( new Point( vert.x, vert.y, vert.z ) );

						var idx = new IndexBuffer();
						var ptsLenHalved = hpsPts.length >> 1;
						// нижняя грань
						for ( i in 1...( ptsLenHalved - 1 ) ) {
							idx.push( 0 );
							idx.push( i );
							idx.push( i + 1 );
						}

						// боковые грани
						for ( i in 0...ptsLenHalved ) {
							var ipp = ( i == ptsLenHalved - 1 ) ? 0 : i + 1;

							idx.push( i + ptsLenHalved );
							idx.push( ptsLenHalved + ipp );
							idx.push( i );

							idx.push( ipp + ptsLenHalved );
							idx.push( ipp );
							idx.push( i );
						}

						// верхняя грань
						for ( i in ( ( ptsLenHalved ) + 1 ) ... ( hpsPts.length - 1 ) ) {
							idx.push( i + 1 );
							idx.push( i );
							idx.push( ptsLenHalved );
						}

						var poly = new Polygon( hpsPts, idx );
						var rigidTransform = rbList.getTransform();

						mesh = new Mesh( poly, Boot.inst.s3d );
						mesh.x = rigidTransform._positionX;
						mesh.y = rigidTransform._positionY;
						mesh.z = rigidTransform._positionZ;
						mesh.material.mainPass.wireframe = true;
						mesh.material.color = Color.intToVector( color );
						mesh.material.color.w = 0.5;
						mesh.material.shadows = false;
					default:
				}

				// if ( mesh != null )
				// 	mesh.material.mainPass.addShader( new VoxelDepther( 10 ) );
				meshes[shape] = mesh;
				shape = shape.getNext();
			}

			rbList = rbList.getNext();
		}
	}

	override function onDispose() {
		super.onDispose();
		for ( mesh in meshes ) {
			mesh.remove();
		}
		meshes = [];
	}
}
