package en.objs;

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
	public var isoWidth(default, set) : Float;

	inline function set_isoWidth( v : Float ) return isoWidth = isLong ? v : throw "set isLong before setting iso width/height";

	public var isoHeight(default, set) : Float;

	inline function set_isoHeight( v : Float ) return isoHeight = isLong ? v : throw "set isLong before setting iso width/height";

	public var verts(get, null) : Dynamic;

	public var xOff = 0.;
	public var yOff = 0.;

	inline function get_verts() {
		return if ( !isLong ) {
			right : { x : 0., z : -0. },
			down : { x : -0., z : -0. },
			left : { x : -0., z : 0. },
			up : { x : 0., z : 0. }
		} else {
			right : { x : 10 * isoWidth, z : -10 * isoHeight },
			down : { x : -10 * isoWidth, z : -10 * isoHeight },
			left : { x : -10 * isoWidth, z : 10 * isoHeight },
			up : { x : 10 * isoWidth, z : 10 * isoHeight }
		};
	}

	public var isLong : Bool = false;

	public var polyPrim : Polygon;
	public var isoDebugMesh : Mesh;

	#if( debug && depth_debug )
	var pts : Array<Point> = [];
	#end

	public function new( tile : Tile, ppu : Float = 1, faceCamera : Bool = true, ?parent : Object ) {
		super(tile, ppu, faceCamera, parent);

		#if( debug && depth_debug )
		renewDebugPts();
		#end
	}

	public function renewDebugPts() {
		#if( debug && depth_debug )
		pts = [];
		pts.push(new Point(getIsoVerts().right.x + xOff, 1, getIsoVerts().right.y + yOff));
		pts.push(new Point(getIsoVerts().down.x + xOff, 1, getIsoVerts().down.y + yOff));
		pts.push(new Point(getIsoVerts().left.x + xOff, 1, getIsoVerts().left.y + yOff));
		pts.push(new Point(getIsoVerts().up.x + xOff, 1, getIsoVerts().up.y + yOff));

		var idx = new IndexBuffer();
		idx.push(1);
		idx.push(2);
		idx.push(0);

		idx.push(2);
		idx.push(3);
		idx.push(0);

		if ( isoDebugMesh != null ) isoDebugMesh.remove();

		polyPrim = new Polygon(pts, idx);
		polyPrim.addUVs();
		polyPrim.addNormals();

		isoDebugMesh = new Mesh(polyPrim, this);
		isoDebugMesh.rotate(0, 0, M.toRad(-90));
		isoDebugMesh.material.color.setColor(0xffffff);
		isoDebugMesh.material.shadows = false;
		isoDebugMesh.material.mainPass.wireframe = true;
		#end
	}

	public function getIsoBounds() {
		var cartVerts = getIsoVerts();
		return {
			xMin : x + Std.int((cartVerts.left.x + xOff)),
			xMax : x + Std.int((cartVerts.right.x + xOff)),

			zMin : z + Std.int((cartVerts.left.y + yOff)),
			zMax : z + Std.int((cartVerts.right.y + yOff)),
		}
	}

	public function getIsoVerts() {
		return {
			right : cartToIso(verts.right.x, verts.right.z),
			down : cartToIso(verts.down.x, verts.down.z),
			left : cartToIso(verts.left.x, verts.left.z),
			up : cartToIso(verts.up.x, verts.up.z),
		};
	}

	override function getBoundsRec( b : Bounds ) : Bounds {
		b.add(plane.getBounds());
		return super.getBoundsRec(b);
	}

	public function flipX() {
		var temp = isoWidth;
		isoWidth = isoHeight;
		isoHeight = temp;
		renewDebugPts();
	}
}
