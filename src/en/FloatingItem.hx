package en;

import tools.Save;
import hxbit.Serializer;
import en.objs.IsoTileSpr;
import en.player.Player;
import format.tmx.Data.TmxObject;
import h2d.Bitmap;
import h3d.Vector;
import h3d.col.Point;
import h3d.mat.Material;
import h3d.mat.Texture;
import h3d.prim.UV;
import h3d.scene.Mesh;
import h3d.scene.Object;
import hxGeomAlgo.HxPoint;
import shader.PolyDedepther;

class FloatingItem extends Interactive {
	var item : en.Item;
	var polyMesh : Mesh;
	var shadowMesh : IsoTileSpr;
	var shadowTex : Texture;
	var deDepth : PolyDedepther;
	var baseRotation = Math.random() * M.toRad(360);
	var startWave = Math.random() * 9999;
	var rotCont : Object;

	public function new( ?x : Float = 0, ?z : Float = 0, item : en.Item, ?tmxObj : TmxObject ) {
		this.item = item;

		super(x, z, tmxObj);
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		if ( spr == null ) spr = new HSprite(item.spr.lib, item.spr.groupName, entParent);

		super.init(x, z, tmxObj);

		spr.setCenterRatio(0, 0);
		spr.tile.getTexture().filter = Nearest;

		mesh.remove();
		mesh = null;

		var revPts = translatedPoints.copy();
		for ( i in revPts ) translatedPoints.push(new Point(i.x, i.y + 1.5, i.z));

		var revTri = polygonized.copy();
		revTri.reverse();
		for ( i in revTri ) i.reverse();
		for ( i in revTri ) {
			polygonized.push(i);
		}

		for ( poly in (polygonized.length >> 1) ... polygonized.length ) {
			idx.push(findVertexNumberInArray(polygonized[poly][0], translatedPoints) + Std.int(translatedPoints.length / 2));
			idx.push(findVertexNumberInArray(polygonized[poly][1], translatedPoints) + Std.int(translatedPoints.length / 2));
			idx.push(findVertexNumberInArray(polygonized[poly][2], translatedPoints) + Std.int(translatedPoints.length / 2));
		}

		filterArray(points);
		for ( i in 0...points.length - 1 ) {
			var temp = [];
			try {
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints));
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints) + Std.int(translatedPoints.length / 2));
				temp.push(findVertexNumberInArray(points[i], translatedPoints));

				temp.push(findVertexNumberInArray(points[i], translatedPoints));
				temp.push(findVertexNumberInArray(points[i + 1], translatedPoints) + Std.int(translatedPoints.length / 2));
				temp.push(findVertexNumberInArray(points[i], translatedPoints) + Std.int(translatedPoints.length / 2));
			}
			catch( e:Any )
				continue;
			for ( i in temp ) idx.push(i);
		}
		// the last frame element
		idx.push(findVertexNumberInArray(points[0], translatedPoints));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints));

		idx.push(findVertexNumberInArray(points[0], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[points.length - 1], translatedPoints) + Std.int(translatedPoints.length / 2));
		idx.push(findVertexNumberInArray(points[0], translatedPoints));

		// UVs gen
		polyPrim.unindex();
		polyPrim.uvs = [];
		for ( i in 0...(translatedPoints.length >> 1) ) polyPrim.uvs.push(new UV((translatedPoints[i].x) / (16),
			(translatedPoints[i].z) / (16))); // 16 это ширина и высота тайла соответственно
		var i = translatedPoints.length - 1;
		var m = polyPrim.uvs.length;

		while( i >= m ) {
			polyPrim.uvs.push(new UV((translatedPoints[i].x) / (16), (translatedPoints[i].z) / (16)));
			i--;
		}
		for ( i in translatedPoints.length ... idx.length ) polyPrim.uvs.push(new UV(0, 0));

		spr.drawTo(tex);
		tex.filter = Nearest;

		polyPrim.addNormals();
		polyPrim.addTangents();

		polyMesh = new Mesh(polyPrim, Material.create(tex), Boot.inst.s3d);
		polyMesh.material.mainPass.depth(true, LessEqual);
		polyMesh.material.mainPass.culling = Front;
		polyMesh.material.shadows = false;
		polyMesh.material.mainPass.enableLights = false;

		deDepth = polyMesh.material.mainPass.addShader(new shader.PolyDedepther(z));
		deDepth.xRotAngle = -rotAngle;
		var meshSize = polyMesh.getBounds().getSize();

		polyPrim.translate(-.5 * meshSize.x - 1, -.5 * meshSize.y, -.5 * meshSize.z);

		polyMesh.scale(2 / 3);
		// polyMesh.setRotationAxis(1, 0, 0, rotAngle);
		// polyMesh.setDirection(new Vector(1, 0, 0, 1));
		polyMesh.rotate(M.toRad(180), 0, baseRotation);
		// polyMesh.y = 1;

		var shadowSpr = new HSprite(Assets.items);
		shadowSpr.set("shadow");
		shadowSpr.setCenterRatio();
		shadowMesh = new IsoTileSpr(shadowSpr.tile, Boot.inst.s3d);
		shadowMesh.rotate(0, 0, M.toDeg(-90));

		shadowMesh.material.mainPass.enableLights = false;
		shadowMesh.material.mainPass.depth(false, Less);
		shadowMesh.scale(0.6);
		shadowMesh.scaleZ = (0.4);

		shadowTex = new Texture(Std.int(shadowSpr.tile.width), Std.int(shadowSpr.tile.height), [Target]);
		var shadowBmp = new Bitmap(shadowSpr.tile);
		shadowBmp.drawTo(shadowTex);

		var shape = new differ.shapes.Circle(0, 0, 4);
		collisions.set(shape, { cent : new Vector(), offset : new Vector() });
	}

	// public static function
	override function update() {
		super.update();
		//
		// var tile = Tile.fromTexture(shadowTex);
		// shadowMesh.tile = tile;
	}

	override function postUpdate() {
		super.postUpdate();
		checkCollisions();
		// polyMesh.material.texture.clear(0, 0);
		// bmp.tile = spr.tile;
		// bmp.drawTo(polyMesh.material.texture);

		shadowMesh.x = footX;
		shadowMesh.z = footY;

		polyMesh.x = footX;
		polyMesh.z = footY + 4 * Math.sin((Game.inst.ftime + startWave) / 34) + 10;

		// polyMesh.y = 0.01;

		polyMesh.rotate(0, 0, 0.016 * tmod);
		deDepth.objZ = (polyMesh.z - footY) * Math.sin(-rotAngle);

		if ( !isLocked() ) bumpAwayFrom(Player.inst, distPx(Player.inst) < 20 ? -.065 * tmod : 0);

		if ( player != null && distPx(player) < 10 && !isLocked() ) {
			player.ui.inventory.invGrid.giveItem(item, player) != null ? {
				destroy();
				if ( sqlId != null ) Save.inst.removeEntityById(sqlId);
			} : {};
		}
	}

	override function checkCollisions() {
		super.checkCollisions();
		checkCollsAgainstAll();
	}

	public override function frameEnd() {
		super.frameEnd();
	}

	@:keep
	override function customSerialize( ctx : Serializer ) {
		if ( item != null ) {
			ctx.addString(Std.string(item.cdbEntry));
			ctx.addInt(item.amount);
		} else {
			ctx.addString("null");
			ctx.addInt(0);
		}
		super.customSerialize(ctx);
	}

	@:keep
	override function customUnserialize( ctx : Serializer ) {
		var itemCdb = ctx.getString();
		var itemAmt = ctx.getInt();

		if ( itemCdb != "null" ) {
			var item = Item.fromCdbEntry(Data.items.resolve(itemCdb).id, itemAmt);
			item.containerEntity = this;
			this.item = item;
		}
		super.customUnserialize(ctx);
	}

	function filterArray( array : Array<HxPoint> ) {
		var i = 0;
		do {
			if ( (((array[i].x == array[i + 1].x) && (array[i + 1].x == array[i + 2].x))
				|| ((array[i].y == array[i + 1].y) && (array[i + 1].y == array[i + 2].y))) ) {
				array.remove(array[i + 1]);
				if ( i > 1 ) i--;
			}
			if ( (((array[array.length - 1].x == array[0].x) && (array[0].x == array[1].x))
				|| ((array[array.length - 1].y == array[0].y) && (array[0].y == array[1].y))) ) array.remove(array[0]);
			if ( (((array[array.length - 2].x == array[array.length - 1].x) && (array[array.length - 1].x == array[0].x))
				|| ((array[array.length - 2].y == array[array.length - 1].y)
					&& (array[array.length - 1].y == array[0].y))) ) array.remove(array[array.length - 1]);
			i++;
		} while( i <= array.length - 3 );
	}

	override function dispose() {
		polyMesh.remove();
		if ( shadowTex != null && !shadowTex.isDisposed() ) shadowTex.dispose();

		shadowMesh.remove();
		super.dispose();
	}
}
