package en.objs;

import h3d.Vector;
import h3d.scene.Mesh;
import h3d.prim.Polygon;
import h3d.col.Point;
import hxd.IndexBuffer;
import h3d.scene.Object;
import h2d.Tile;
import ch3.scene.TileSprite;

class IsoTileSpr extends TileSprite {
	public var isoWidth(default, set):Int;

	inline function set_isoWidth(v:Int)
		return isoWidth = isLong ? v : throw "set isLong before setting iso width/height";

	public var isoHeight(default, set):Int;

	inline function set_isoHeight(v:Int)
		return isoHeight = isLong ? v : throw "set isLong before setting iso width/height";

	public var verts(get, null):Dynamic;

	inline function get_verts() {
		return if (!isLong) {
			right: {x: 0., z: -0.},
			down: {x: -0., z: -0.},
			left: {x: -0., z: 0.},
			up: {x: 0., z: 0.}
		} else {
			right: {x: 10 * isoWidth, z: -10 * isoHeight},
			down: {x: -10 * isoWidth, z: -10 * isoHeight},
			left: {x: -10 * isoWidth, z: 10 * isoHeight},
			up: {x: 10 * isoWidth, z: 10 * isoHeight}
		};
	}

	public var isLong:Bool = false;

	public var polyPrim:Polygon;
	public var isoDebugMesh:Mesh;

	var pts:Array<Point> = [];

	public function new(tile:Tile, ppu:Float = 1, faceCamera:Bool = true, ?parent:Object) {
		super(tile, ppu, faceCamera, parent);

		// pts.push(new Point(verts.right.x, 0, verts.right.z));
		// pts.push(new Point(verts.down.x, 0, verts.down.z));
		// pts.push(new Point(verts.left.x, 0, verts.left.z));
		// pts.push(new Point(verts.up.x, 0, verts.up.z));
		#if (debug && dispDepthBoxes)
		renewDebugPts();

		var idx = new IndexBuffer();
		idx.push(1);
		idx.push(2);
		idx.push(0);

		idx.push(2);
		idx.push(3);
		idx.push(0);
		polyPrim = new Polygon(pts, idx);
		polyPrim.addUVs();
		polyPrim.addNormals();

		isoDebugMesh = new Mesh(polyPrim, this);
		isoDebugMesh.rotate(0, 0, M.toRad(-90));
		isoDebugMesh.material.color.setColor(0xffffff);
		isoDebugMesh.material.shadows = false;
		isoDebugMesh.material.mainPass.wireframe = true;
		// isoDebugMesh.material.mainPass.depth(false, Always);
		#end
	}

	public function renewDebugPts() {
		pts = [];
		pts.push(new Point(getIsoVerts().right.x, 0, getIsoVerts().right.y));
		pts.push(new Point(getIsoVerts().down.x, 0, getIsoVerts().down.y));
		pts.push(new Point(getIsoVerts().left.x, 0, getIsoVerts().left.y));
		pts.push(new Point(getIsoVerts().up.x, 0, getIsoVerts().up.y));
		if (polyPrim != null)
			polyPrim.points = pts;
	}

	public function getIsoBounds() {
		var verts1 = getIsoVerts();
		return {
			xMin: x + Std.int((verts1.left.x)),
			xMax: x + Std.int((verts1.right.x)),

			zMin: z + Std.int((verts1.left.y)),
			zMax: z + Std.int((verts1.right.y)),

			// xMin: Std.int((verts1.left.x)),
			// xMax: Std.int((verts1.right.x)),

			// zMin: Std.int((verts1.down.y)),
			// zMax: Std.int((verts1.up.y)),
		}
	}

	function getIsoVerts() {
		return {
			right: cartToIso(verts.right.x, verts.right.z),
			down: cartToIso(verts.down.x, verts.down.z),
			left: cartToIso(verts.left.x, verts.left.z),
			up: cartToIso(verts.up.x, verts.up.z),
		};
	}
}
