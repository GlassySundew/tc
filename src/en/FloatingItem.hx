package en;

import h3d.mat.Material;
import h2d.Tile;
import h3d.scene.TileSprite;
import hxGeomAlgo.HxPoint;
import h3d.col.Point;
import h2d.Bitmap;
import hxd.BitmapData;
import hxd.Res;
import h3d.mat.Texture;
import h3d.prim.UV;
import h3d.prim.Polygon;
import hxd.IndexBuffer;
import h3d.scene.Mesh;
import format.tmx.Data.TmxObject;

class FloatingItem extends Interactive {
	var item:Item;
	var polyMesh:Mesh;
	var shadowMesh:TileSprite;
	var shadowTex:Texture;

	var baseRotation = Math.random() * M.toRad(360);
	var baseWave = Math.random()* 9999;

	public function new(?x:Float = 0, ?z:Float = 0, item:Item, ?tmxObj:TmxObject) {
		if (spr == null)
			spr = item.spr;
		spr.setCenterRatio(0, 0);
		this.item = item;
		spr.tile.getTexture().filter = Nearest;
		super(x, z, tmxObj);
		mesh = null;
		footX = x;
		footY = z;
		var revPts = translatedPoints.copy();
		for (i in revPts)
			translatedPoints.push(new Point(i.x, i.y - 1.5, i.z));

		var revTri = polygonized.copy();
		revTri.reverse();
		for (i in revTri)
			i.reverse();
		for (i in revTri) {
			polygonized.push(i);
		}

		for (poly in (polygonized.length >> 1)...polygonized.length) {
			idx.push(findVertexNumberInArray(polygonized[poly][0], translatedPoints) + Std.int(translatedPoints.length / 2));
			idx.push(findVertexNumberInArray(polygonized[poly][1], translatedPoints) + Std.int(translatedPoints.length / 2));
			idx.push(findVertexNumberInArray(polygonized[poly][2], translatedPoints) + Std.int(translatedPoints.length / 2));
		}

		filterArray(points);
		for (i in 0...points.length - 1) {
			var temp = [];
			try {
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints));
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints) + Std.int(translatedPoints.length / 2));
				temp.push(findVertexNumberInArray(points[i], translatedPoints));

				temp.push(findVertexNumberInArray(points[i], translatedPoints));
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints) + Std.int(translatedPoints.length / 2));
				temp.push(findVertexNumberInArray(points[i], translatedPoints) + Std.int(translatedPoints.length / 2));
			} catch (e:Any)
				continue;
			for (i in temp)
				idx.push(i);
		}
		idx.push(findVertexNumberInArray(points[0], translatedPoints));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints));

		idx.push(findVertexNumberInArray(points[0], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[0], translatedPoints));

		// UVs gen
		polyPrim.unindex();
		polyPrim.uvs = [];

		for (i in 0...(translatedPoints.length >> 1))
			polyPrim.uvs.push(new UV((translatedPoints[i].x) / (16), (translatedPoints[i].z) / (16))); // 16 это ширина и высота тайла соответственно
		var i = translatedPoints.length - 1;
		var m = polyPrim.uvs.length;

		while (i >= m) {
			polyPrim.uvs.push(new UV((translatedPoints[i].x) / (16), (translatedPoints[i].z) / (16)));
			i--;
		}
		for (i in translatedPoints.length...idx.length)
			polyPrim.uvs.push(new UV(0, 0));

		tex = new Texture(Std.int(spr.tile.width), Std.int(spr.tile.height), [Target]);
		bmp = new Bitmap(spr.tile);
		bmp.drawTo(tex);
		tex.filter = Nearest;
		polyPrim.addNormals();
		polyPrim.addTangents();

		polyMesh = new Mesh(polyPrim, Material.create(tex), Boot.inst.s3d);
		polyMesh.material.mainPass.depth(true, Less);
		polyMesh.material.shadows = false;
		polyMesh.material.mainPass.enableLights = false;

		var meshSize = polyMesh.getBounds().getSize();

		polyPrim.translate(-.5 * meshSize.x - 1, 0, -meshSize.z - 10);
		polyMesh.scale(2 / 3);
		polyMesh.setRotationAxis(1, 0, 0, -rotAngle);
		polyMesh.rotate(M.toRad(180) + rotAngle, 0, baseRotation);
		var shadowSpr = new HSprite(Assets.items);

		shadowSpr.set("shadow");
		shadowMesh = new TileSprite(shadowSpr.tile, Boot.inst.s3d);
		shadowMesh.material.mainPass.setBlendMode(Alpha);
		shadowMesh.material.mainPass.enableLights = false;
		shadowMesh.material.mainPass.depth(false, Less);
		shadowMesh.scale(0.6);
		shadowMesh.scaleZ = (0.4);

		shadowTex = new Texture(Std.int(shadowSpr.tile.width), Std.int(shadowSpr.tile.height), [Target]);
		new Bitmap(shadowSpr.tile).drawTo(shadowTex);
		bottomAlpha = -2;
	}

	override function update() {
		super.update();

		//
		// var tile = Tile.fromTexture(shadowTex);
		// shadowMesh.tile = tile;
	}

	override function postUpdate() {
		super.postUpdate();

		// polyMesh.material.texture.clear(0, 0);
		// bmp.tile = spr.tile;
		// bmp.drawTo(polyMesh.material.texture);
		shadowMesh.x = footX;
		shadowMesh.z = footY;
		shadowMesh.y = 0;
		polyMesh.x = footX;
		polyMesh.z = footY + 4 * Math.sin((Game.inst.ftime + baseWave ) / 34);
		polyMesh.y = (bottomAlpha * .5 * polyMesh.scaleZ * Math.sin(rotAngle) / (180 / Math.PI)) + 1;
		polyMesh.rotate(0, 0, 0.016);
	}

	public override function frameEnd() {
		bmp.tile = spr.tile;
		bmp.drawTo(tex);
	}

	function filterArray(array:Array<HxPoint>) {
		var i = 0;

		// array.remove(array[array.length - 1]);
		// array.remove(array[array.length - 1]);
		do {
			if ((((array[i].x == array[i + 1].x) && (array[i + 1].x == array[i + 2].x))
				|| ((array[i].y == array[i + 1].y) && (array[i + 1].y == array[i + 2].y)))) {
				array.remove(array[i + 1]);
				if (i > 1)
					i--;
			}
			if ((((array[array.length - 1].x == array[0].x) && (array[0].x == array[1].x))
				|| ((array[array.length - 1].y == array[0].y) && (array[0].y == array[1].y))))
				array.remove(array[0]);
			if ((((array[array.length - 2].x == array[array.length - 1].x) && (array[array.length - 1].x == array[0].x))
				|| ((array[array.length - 2].y == array[array.length - 1].y) && (array[array.length - 1].y == array[0].y))))
				array.remove(array[array.length - 1]);
			i++;
		} while (i <= array.length - 3);
	}
}
