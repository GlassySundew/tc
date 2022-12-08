package en.objs;

import util.Util;
import haxe.exceptions.NotImplementedException;
import en.EntityTmxDataParser.EntityDepthConfig;
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

	public var isoLeftPt : Vector;
	public var isoRightPt : Vector;

	public var conf( default, set ) : EntityDepthConfig;

	inline function set_conf( v : EntityDepthConfig ) : EntityDepthConfig {
		conf = v;
		updateIsoCoords();
		#if( debug && depth_debug )
		renewDebugPts();
		#end
		return v;
	}

	public var verts : Dynamic;

	public var isLong( get, never ) : Bool;

	inline function get_isLong() : Bool {
		return ( conf.leftPoint.x == conf.rightPoint.x
			&& conf.leftPoint.y == conf.leftPoint.y );
	}

	public var isoDebugMesh : Mesh;

	public function new( tile : Tile, ppu : Float = 1, faceCamera : Bool = true, ?parent : Object ) {
		super( tile, ppu, faceCamera, parent );
	}

	public function updateIsoCoords() {
		isoLeftPt = Util.cartToIso( conf.leftPoint.x, conf.leftPoint.y );
		isoLeftPt = Util.isoToCart( isoLeftPt.x, isoLeftPt.y );

		isoRightPt = Util.cartToIso( conf.rightPoint.x, conf.rightPoint.y );
		isoRightPt = Util.isoToCart( isoRightPt.x, isoRightPt.y );
	}

	public function renewDebugPts() {
		// #if( debug && depth_debug )
		// if(isoDebugMes)
		// pts = [];
		// pts.push( new Point( verts.right.x + xOff, verts.right.y + yOff ) );
		// pts.push( new Point( verts.down.x + xOff, verts.down.y + yOff ) );
		// pts.push( new Point( verts.left.x + xOff, verts.left.y + yOff ) );
		// pts.push( new Point( verts.up.x + xOff, verts.up.y + yOff ) );

		// var idx = new IndexBuffer();
		// idx.push( 1 );
		// idx.push( 2 );
		// idx.push( 0 );

		// idx.push( 2 );
		// idx.push( 3 );
		// idx.push( 0 );

		// if ( isoDebugMesh != null ) isoDebugMesh.remove();

		// var polyPrim = new Polygon( pts, idx );
		// polyPrim.addUVs();
		// polyPrim.addNormals();

		// isoDebugMesh = new Mesh( polyPrim, this );
		// isoDebugMesh.rotate( 0, 0, M.toRad( -90 ) );
		// isoDebugMesh.material.color.setColor( 0xffffff );
		// isoDebugMesh.material.shadows = false;
		// isoDebugMesh.material.mainPass.wireframe = true;
		// #end
	}

	public inline function getIsoBounds() {
		return {
			xMin : x + isoLeftPt.x,
			xMax : x + isoRightPt.x,
			yMin : y + isoLeftPt.y,
			yMax : y + isoRightPt.y,
		}
	}

	override function getBoundsRec( b : Bounds ) : Bounds {
		b.add( plane.getBounds() );
		return super.getBoundsRec( b );
	}

	public function flipX() {
		throw new NotImplementedException();

		renewDebugPts();
	}
}
