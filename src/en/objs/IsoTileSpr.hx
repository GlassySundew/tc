package en.objs;

import dn.M;
import h3d.col.Bounds;
import h3d.Vector;
import h3d.scene.Mesh;
import h3d.prim.Polygon;
import h3d.col.Point;
import hxd.IndexBuffer;
import h3d.scene.Object;
import h2d.Tile;
import ch3.scene.TileSprite;

class IsoTileSpr extends TileSprite {

	public var isoWidth : Float;
	public var isoHeight : Float;

	public var verts : Dynamic;

	public var xOff = 0.;
	public var yOff = 0.;

	public var isLong( get, never ) : Bool;

	inline function get_isLong() : Bool {
		return ( isoHeight > 0 || isoWidth > 0 );
	}

	public var polyPrim : Polygon;
	public var isoDebugMesh : Mesh;

	#if( debug && depth_debug )
	var pts : Array<Point> = [];
	#end

	public function new( tile : Tile, ppu : Float = 1, faceCamera : Bool = true, ?parent : Object ) {
		super( tile, ppu, faceCamera, parent );

		refreshVerts();

		#if( debug && depth_debug )
		renewDebugPts();
		#end
	}

	public function refreshVerts() {
		verts = if ( !isLong ) {
			right : { x : 0., y : -0. },
			down : { x : -0., y : -0. },
			left : { x : -0., y : 0. },
			up : { x : 0., y : 0. }
		} else {
			right : { x : 10 * isoWidth, y : -10 * isoHeight },
			down : { x : 10 * isoWidth, y : 10 * isoHeight },
			left : { x : -10 * isoWidth, y : 10 * isoHeight },
			up : { x : -10 * isoWidth, y : -10 * isoHeight }
		};
	}

	public function renewDebugPts() {
		#if( debug && depth_debug )
		pts = [];
		pts.push( new Point( verts.right.x + xOff, verts.right.y + yOff ) );
		pts.push( new Point( verts.down.x + xOff, verts.down.y + yOff ) );
		pts.push( new Point( verts.left.x + xOff, verts.left.y + yOff ) );
		pts.push( new Point( verts.up.x + xOff, verts.up.y + yOff ) );

		var idx = new IndexBuffer();
		idx.push( 1 );
		idx.push( 2 );
		idx.push( 0 );

		idx.push( 2 );
		idx.push( 3 );
		idx.push( 0 );

		if ( isoDebugMesh != null ) isoDebugMesh.remove();

		polyPrim = new Polygon( pts, idx );
		polyPrim.addUVs();
		polyPrim.addNormals();

		isoDebugMesh = new Mesh( polyPrim, this );
		isoDebugMesh.rotate( 0, 0, M.toRad( -90 ) );
		isoDebugMesh.material.color.setColor( 0xffffff );
		isoDebugMesh.material.shadows = false;
		isoDebugMesh.material.mainPass.wireframe = true;
		#end
	}

	public function getIsoBounds() {
		return {
			xMin : x + Std.int( ( verts.left.x + xOff ) ),
			xMax : x + Std.int( ( verts.right.x + xOff ) ),

			yMin : y + Std.int( ( verts.left.y + yOff ) ),
			yMax : y + Std.int( ( verts.right.y + yOff ) ),
		}
	}

	override function getBoundsRec( b : Bounds ) : Bounds {
		b.add( plane.getBounds() );
		return super.getBoundsRec( b );
	}

	public function flipX() {
		var temp = isoWidth;
		isoWidth = isoHeight;
		isoHeight = temp;
		renewDebugPts();
	}
}
