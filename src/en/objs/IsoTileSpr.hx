package en.objs;

import h3d.scene.RenderContext;
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

	public var conf( default, set ) : EntityDepthConfig;

	inline function set_conf( v : EntityDepthConfig ) : EntityDepthConfig {
		conf = v;
		#if( debug && depth_debug )
		renewDebugPts();
		#end
		return v;
	}

	public var isLong( get, never ) : Bool;

	inline function get_isLong() : Bool {
		return ( conf.leftPoint.x == conf.rightPoint.x
			&& conf.leftPoint.y == conf.leftPoint.y );
	}

	public var isoDebugMesh : Mesh;
	public function new( tile : Tile, ppu : Float = 1, faceCamera : Bool = true, ?parent : Object ) {
		super( tile, ppu, faceCamera, parent );
	}

	public function renewDebugPts() {
		#if( debug && depth_debug )
		if ( isoDebugMesh != null ) isoDebugMesh.remove();

		var pts = [];
		pts.push( new Point( conf.leftPoint.x, conf.leftPoint.y ) );
		pts.push( new Point( conf.leftPoint.x, conf.rightPoint.y ) );
		pts.push( new Point( conf.rightPoint.x, conf.rightPoint.y ) );
		pts.push( new Point( conf.rightPoint.x, conf.leftPoint.y ) );

		var idx = new IndexBuffer();
		idx.push( 1 );
		idx.push( 2 );
		idx.push( 0 );

		idx.push( 2 );
		idx.push( 3 );
		idx.push( 0 );

		if ( isoDebugMesh != null ) isoDebugMesh.remove();

		var polyPrim = new Polygon( pts, idx );
		polyPrim.addUVs();
		polyPrim.addNormals();

		isoDebugMesh = new Mesh( polyPrim, Boot.inst.s3d );
		isoDebugMesh.material.color.setColor( 0xe50b0b );
		isoDebugMesh.material.shadows = false;
		isoDebugMesh.material.mainPass.wireframe = true;
		#end
	}

	override function onRemove() {
		super.onRemove();
		if ( isoDebugMesh != null ) isoDebugMesh.remove();
	}

	#if !debug inline #end
	public function getIsoBounds() {

		return {
			xMin : x + conf.leftPoint.x,
			xMax : x + conf.rightPoint.x,
			yMin : y + conf.leftPoint.y,
			yMax : y + conf.rightPoint.y,
		}
	}

	override function sync( ctx : RenderContext ) {
		super.sync( ctx );
		#if depth_debug
		if ( isoDebugMesh != null ) {
			isoDebugMesh.x = x;
			isoDebugMesh.y = y;
			isoDebugMesh.z = z;
		}
		#end
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
