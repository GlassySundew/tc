package en;

import h3d.scene.Object;
import h3d.scene.Sphere;
import h3d.scene.Mesh;
import hxd.IndexBuffer;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import h3d.col.Bounds;
import hxGeomAlgo.PoleOfInaccessibility;
import hxGeomAlgo.HxPoint;
import h2d.col.Point;
import hxbit.Serializable;
import differ.Collision;
import differ.shapes.Shape;
import dn.heaps.slib.HSprite;
import en.objs.IsoTileSpr;
import en.player.Player;
import format.tmx.Data.TmxObject;
import format.tmx.Data.TmxTilesetTile;
import format.tmx.Tools;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import hxbit.NetworkSerializable;
import ui.InventoryGrid.CellGrid;

class Entity implements NetworkSerializable {
	public static var ALL : Array<Entity> = [];
	public static var GC : Array<Entity> = [];
	/**
		Map of multiple shapes, 1st vector is a center of polygon Shape, 2nd polygon is a position of a poly
	**/
	public var collisions : Map<Shape, { cent : Vector, offset : Vector }>;

	public var level : Level;

	public var destroyed(default, null) = false;
	public var tmod(get, never) : Float;

	public var xr = 0.5;
	public var yr = 0.5;
	public var zr = 0.;

	public var dx = 0.;
	public var dy = 0.;
	public var dz = 0.;
	public var bdx = 0.;
	public var bdy = 0.;

	public var dxTotal(get, never) : Float;

	inline function get_dxTotal() return dx + bdx;

	public var dyTotal(get, never) : Float;

	inline function get_dyTotal() return dy + bdy;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var bumpReduction = 0.;

	public var centerX(get, never) : Float;

	inline function get_centerX() return footX;

	public var centerY(get, never) : Float;

	inline function get_centerY() return footY - 11;

	public var dir(default, set) = 6;

	inline function get_tmod() {
		return #if headless GameServer.inst.tmod #else if ( Game.inst != null ) Game.inst.tmod else
			GameClient.inst.tmod #end;
	}

	public var player(get, never) : en.player.Player;

	inline function get_player() return Player.inst;

	@:s public var uid : Int;

	@:s public var netX(default, set) : Float;
	@:s public var netY(default, set) : Float;

	function set_netX( v : Float ) {
		return netX = v;
	}

	function set_netY( v : Float ) {
		return netY = v;
	}

	@:s public var footX(default, set) : Float;

	// inline function get_footX() return (cx + xr);

	function set_footX( v : Float ) { // небольшой костыль
		// xr = ((v)) % 1;
		// cx = (Math.floor((v)));
		return this.footX = v;
	}

	@:s public var footY(default, set) : Float;

	// inline function get_footY() return (cy + yr - zr);

	function set_footY( v : Float ) { // аналогично
		// yr = ((v)) % 1;
		// cy = (Math.floor((v)));
		return this.footY = v;
	}

	public var tmxTile(get, never) : TmxTilesetTile;

	inline function get_tmxTile() return Tools.getTileByGid(Level.inst.data, tmxObj.objectType.getParameters()[0]);

	public var sqlId : Null<Int>;

	public var tmxObj : TmxObject;
	public var colorAdd : h3d.Vector;
	public var spr : HSprite;
	public var mesh : IsoTileSpr;
	public var tmpDt : Float;
	public var tmpCur : Float;
	public var lastFootX : Float;
	public var lastFootY : Float;
	public var curFrame : Float = 0;

	@:s public var sprFrame : { group : String, frame : Int };

	private var rotAngle : Float = -0.01;
	private var tex : Texture;
	private var texTile : Tile;

	public var cd : dn.Cooldown;
	public var tw : Tweenie;
	@:s public var flippedX : Bool;
	public var pivotChanged = true;

	public static var isoCoefficient = 1.2;

	public var invGrid : CellGrid;

	public function new( ?x : Float = 0, ?z : Float = 0, ?tmxObj : Null<TmxObject> ) {
		init(x, z, tmxObj);

		flippedX = false;
	}

	public function init( ?x : Float, ?z : Float, ?tmxObj : Null<TmxObject> ) {
		if ( !ALL.contains(this) ) ALL.push(this);

		collisions = new Map<Shape, { cent : Vector, offset : Vector }>();
		cd = new dn.Cooldown(Const.FPS);
		tw = new Tweenie(Const.FPS);

		if ( spr == null ) throw "spr hasnt been initialised in " + this;
		if ( spr.groupName == null && sprFrame != null ) {
			spr.set(sprFrame.group, sprFrame.frame);
		}
		if ( this.tmxObj == null && tmxObj != null ) this.tmxObj = tmxObj;

		#if !headless
		spr.colorAdd = colorAdd = new h3d.Vector();
		tex = new Texture(Std.int(spr.tile.width), Std.int(spr.tile.height), [Target]);
		spr.tile.getTexture().filter = Nearest;
		spr.blendMode = Alpha;
		spr.drawTo(tex);

		texTile = Tile.fromTexture(tex);
		texTile.getTexture().filter = Nearest;

		mesh = new IsoTileSpr(texTile, false, Boot.inst.s3d);

		mesh.material.mainPass.setBlendMode(AlphaAdd);

		mesh.rotate(tmxObj != null ? M.toRad(tmxObj.rotation) : 0, -rotAngle, M.toRad(90));
		var s = mesh.material.mainPass.addShader(new h3d.shader.ColorAdd());
		s.color = colorAdd;
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.depth(false, Less);
		#end

		// TODO semi-transparent shadow overlapping
		// var s = new h3d.mat.Stencil();
		// s.setFunc(LessEqual, 0);
		// s.setOp(Keep, DecrementWrap, Keep);
		// mesh.material.mainPass.stencil = s;

		if ( x != null && z != null ) setFeetPos(x, z);

		if ( tmxObj != null && tmxObj.flippedVertically ) spr.scaleY = -1;
		if ( tmxObj != null && tmxObj.flippedHorizontally ) {
			Game.inst.delayer.addF(() -> {
				flipX();
			}, 0);
		}
		level = Level.inst;

		#if debug
		updateDebugDisplay();
		#end
	}

	var debugObjs : Array<Object> = [];
	/** update debug centers and colliders poly**/
	public function updateDebugDisplay() {

		for ( i in debugObjs ) if ( i != null ) i.remove();
		debugObjs = [];

		#if entity_centers
		var sphere = new Sphere(0x361bcc, 1, false, mesh);
		sphere.material.mainPass.wireframe = true;
		sphere.material.shadows = false;
		sphere.material.mainPass.depth(true, Less);
		sphere.x = 0.25;
		debugObjs.push(sphere);
		#end

		#if colliders_debug
		Game.inst.delayer.addF(() -> {
			for ( shape => values in collisions ) {
				switch true {
					case Std.isOfType(shape, Polygon) => a if ( a ):
						var pts : Array<h3d.col.Point> = [];

						var poly = cast(shape, Polygon);

						for ( pt in poly.vertices ) {
							pts.push(new h3d.col.Point(pt.x, 0, pt.y));
						}
						var idx = new IndexBuffer();
						for ( i in 1...pts.length - 1 ) {
							idx.push(0);
							idx.push(i);
							idx.push(i + 1);
						}

						var polyPrim = new h3d.prim.Polygon(pts, idx);
						polyPrim.addUVs();
						polyPrim.addNormals();

						var isoDebugMesh = new Mesh(polyPrim, mesh);
						// isoDebugMesh.rotate(0, M.toRad(180), M.toRad(90));
						isoDebugMesh.material.color.setColor(0x361bcc);
						isoDebugMesh.material.shadows = false;
						isoDebugMesh.material.mainPass.wireframe = true;
						isoDebugMesh.material.mainPass.depth(true, Less);

						isoDebugMesh.x = 0.5;
						isoDebugMesh.y = (spr.pivot.centerFactorX * spr.tile.width)
							- values.offset.x;
						isoDebugMesh.z = (spr.pivot.centerFactorY * spr.tile.height)
							- values.offset.y;

						isoDebugMesh.rotate(M.toRad(poly.rotation), 0, -M.toRad(90));
						isoDebugMesh.scaleX = poly.scaleX;
						isoDebugMesh.scaleZ = poly.scaleY;

						debugObjs.push(isoDebugMesh);

					// isoDebugMesh.z = shape.y;
					case Std.isOfType(shape, Circle) => a if ( a ):
						var circle = cast(shape, Circle);

						var sphere = new Sphere(0x361bcc, circle.radius, false, mesh);
						sphere.material.mainPass.wireframe = true;
						sphere.material.shadows = false;
						sphere.material.mainPass.depth(true, Less);
						sphere.scaleZ = circle.scaleY;

						sphere.x = .25;
						sphere.y = (spr.pivot.centerFactorX * spr.tile.width)
							- values.offset.x;
						sphere.z = (spr.pivot.centerFactorY * spr.tile.height)
							- values.offset.y;

						debugObjs.push(sphere);
				}
			}
		}, 3);
		#end
	}

	// network oveeridable
	public function alive() {}

	public function isOfType<T : Entity>( c : Class<T> ) return Std.isOfType(this, c);

	public function as<T : Entity>( c : Class<T> ) : T return Std.downcast(this, c);

	public inline function angTo( e : Entity ) return Math.atan2(e.footY - footY, e.footX - footX);

	public inline function angToPxFree( x : Float, y : Float ) return Math.atan2(y - footY, x - footX);

	public function blink( ?c = 0xffffff ) {
		colorAdd.setColor(c);
		cd.setS("colorMaintain", 0.03);
	}

	public inline function isMoving() return M.fabs(dxTotal) >= 0.01 || M.fabs(dyTotal) >= 0.01;

	public inline function at( x, y ) return footX == x && footY == y;

	public inline function isAlive() {
		return !destroyed; // && life > 0;
	}

	public function isLocked() return cd == null ? true : cd.has("lock");

	public function lock( ?ms : Float ) cd.setMs("lock", ms != null ? ms : 1 / 0);

	public function unlock() if ( cd != null ) cd.unset("lock");

	public function setPivot( x : Float, y : Float ) {
		pivotChanged = true;
		spr.pivot.setCenterRatio(x, y);
	}

	public function dropItem( item : en.Item, ?angle : Float, ?power : Float ) : en.Item {
		angle = angle == null ? Math.random() * M.toRad(360) : angle;
		power = power == null ? Math.random() * .04 * 48 + .01 : power;

		var fItem = new FloatingItem(footX, footY, item);
		fItem.bump(Math.cos(angle) * power, Math.sin(angle) * power, 0);
		fItem.lock(1000);
		item.remove();
		item = null;

		Player.inst.ui.belt.deselectCells();

		return item;
	}

	inline function set_dir( v ) {
		if ( dir != v ) {
			// spr.anim.getCurrentAnim().curFrameCpt = curFrame;
		}

		return dir = v == 0 ? 0 : v == 1 ? 1 : v == 2 ? 2 : v == 3 ? 3 : v == 4 ? 4 : v == 5 ? 5 : v == 6 ? 6 : v == 7 ? 7 : dir;
	}
	/**Flips spr.scaleX, all of collision objects, and sorting rectangle**/
	public function flipX() {
		flippedX = !flippedX;

		spr.scaleX *= -1;
		spr.pivot.centerFactorX = 1 - spr.pivot.centerFactorX;
		pivotChanged = true;

		footX -= (((1 - spr.pivot.centerFactorX * 2) * spr.tile.width));

		updateCollisions();

		for ( shape => value in collisions ) {
			shape.x = shape.y = 0;

			shape.scaleX *= -1;
			value.offset.x *= -1;
			value.offset.x += spr.tile.width;
		}

		if ( mesh.isLong ) mesh.flipX();
		mesh.renewDebugPts();

		try {
			cast(this, Interactive).rebuildInteract();
		}
		catch( e:Dynamic ) {}
		updateDebugDisplay();
	}

	public inline function bumpAwayFrom( e : Entity, spd : Float, ?spdZ = 0., ?ignoreReduction = false ) {
		var a = e.angTo(this);
		bump(Math.cos(a) * spd, Math.sin(a) * spd, spdZ, ignoreReduction);
	}

	public function bump( x : Float, y : Float, z : Float, ?ignoreReduction = false ) {
		var f = ignoreReduction ? 1.0 : 1 - bumpReduction;
		bdx += x * f;
		bdy += y * f;
		dz += z * f;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public inline function distPx( e : Entity ) {
		return M.dist(footX, footY, e.footX, e.footY);
	}
	/**
		подразумевается, что у этой сущности есть длинный изометрический меш
	**/
	public function distPolyToPt( e : Entity ) {
		if ( mesh == null || !mesh.isLong ) return distPx(e); else {

			var verts = mesh.getIsoVerts();

			var pt1 = new HxPoint(footX + mesh.xOff + verts.up.x, footY + mesh.yOff + verts.up.y);
			var pt2 = new HxPoint(footX + mesh.xOff + verts.right.x, footY + mesh.yOff + verts.right.y);
			var pt3 = new HxPoint(footX + mesh.xOff + verts.down.x, footY + mesh.yOff + verts.down.y);
			var pt4 = new HxPoint(footX + mesh.xOff + verts.left.x, footY + mesh.yOff + verts.left.y);

			var dist = PoleOfInaccessibility.pointToPolygonDist(e.footX, e.footY, [[pt1, pt2, pt3, pt4]]);
			return -dist;
		}
	}

	public inline function distPxFree( x : Float, y : Float ) {
		return M.dist(footX, footY, x, y);
	}

	@:rpc public function destroy() {
		if ( !destroyed ) {
			destroyed = true;
			GC.push(this);
		}
	}

	@:keep
	public function customSerialize( ctx : hxbit.Serializer ) {
		if ( tmxObj != null ) ctx.addString(Base64.encode(Bytes.ofString(Serializer.run(tmxObj)))); else
			ctx.addString("");

		ctx.addString(spr.groupName);
		ctx.addInt(spr.frame);

		// items inventory
		if ( invGrid != null ) {
			ctx.addInt(invGrid.grid.length);
			ctx.addInt(invGrid.grid[0].length);

			ctx.addInt(invGrid.cellWidth);
			ctx.addInt(invGrid.cellHeight);
			for ( i in invGrid.grid ) for ( j in i ) {
				if ( j.item != null ) {
					ctx.addString(Std.string(j.item.cdbEntry));
					ctx.addInt(j.item.amount);
				} else {
					ctx.addString("null");
					ctx.addInt(0);
				}
			}
		} else {
			ctx.addInt(0);
			ctx.addInt(0);
		}
	}

	@:keep
	public function customUnserialize( ctx : hxbit.Serializer ) {
		// tmx object
		var tmxUnser = ctx.getString();
		if ( tmxUnser != "" ) tmxObj = Unserializer.run(Base64.decode(tmxUnser).toString());

		sprFrame = {
			group : ctx.getString(),
			frame : ctx.getInt()
		};

		Game.inst.delayer.addF(() -> {
			init();

			level.game.applyTmxObjOnEnt(this);
			if ( flippedX ) {
				Game.inst.delayer.addF(() -> {
					flipX();
					flippedX = true;

					footX += (((1 - spr.pivot.centerFactorX * 2) * spr.tile.width));
				}, 2);
			}
			offsetFootByCenterReversed();
		}, 1);

		// items inventory
		var invHeight = ctx.getInt();
		var invWidth = ctx.getInt();

		if ( invGrid == null && invHeight > 0 && invWidth > 0 ) {
			var cellWidth = ctx.getInt();
			var cellHeight = ctx.getInt();
			invGrid = new CellGrid(invWidth, invHeight, cellWidth, cellHeight, this);
		}
		for ( i in 0...invHeight ) for ( j in 0...invWidth ) {
			var itemString = ctx.getString();
			var itemAmount = ctx.getInt();
			if ( itemString != "null" && itemString != "null" && itemString != null ) {

				var item = Item.fromCdbEntry(Data.items.resolve(itemString).id, itemAmount);
				item.containerEntity = this;

				invGrid.grid[i][j].item = item;
			}
		}
	}

	public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable ) : Bool {
		// trace(op, propId, clientSer, clientSer == this);
		// return #if !headless clientSer == this #else clientSer == this #end;
		return false;
	}

	public function dispose() {
		ALL.remove(this);
		spr.remove();

		if ( mesh != null ) {
			mesh.tile.dispose();
			mesh.primitive.dispose();
			mesh.remove();
		}

		// cd.destroy();
		#if !headless
		tex.dispose();
		#end
		tw.destroy();
		cd = null;
		if ( collisions != null ) for ( i in collisions.keys() ) if ( i != null ) i.destroy();
		collisions = null;
		spr = null;
		mesh = null;
	}

	@:rpc public function setFeetPos( x : Float, y : Float ) {
		footX = x;
		footY = y;
	}

	public function offsetFootByCenter() {
		footX += ((spr.pivot.centerFactorX - .5) * spr.tile.width);
		footY -= (spr.pivot.centerFactorY) * spr.tile.height - spr.tile.height;
	}

	// used by blueprints, to preview entities
	public function offsetFootByCenterReversed() {
		footX -= ((spr.pivot.centerFactorX - .5) * spr.tile.width);
		footY += (spr.pivot.centerFactorY) * spr.tile.height - spr.tile.height;
	}

	// used by save manager, when saved objects are already offset by center
	public function offsetFootByCenterXReversed() {
		footX += ((spr.pivot.centerFactorX - .5) * spr.tile.width);
		footY += (spr.pivot.centerFactorY) * spr.tile.height - spr.tile.height;
	}

	public function kill( by : Null<Entity> ) {
		destroy();
	}

	public function updateCollisions() {
		#if !headless
		if ( collisions != null ) {
			for ( collObj => values in collisions ) {
				collObj.x = footX
					- spr.pivot.centerFactorX * spr.tile.width
					+ values.offset.x;

				collObj.y = footY
					+ spr.pivot.centerFactorY * spr.tile.height
					- values.offset.y;
			}
		}
		#end
	}

	public function checkCollsAgainstAll( ?doMove : Bool = true ) : Bool {
		#if !headless
		var collided = false;
		for ( ent in Entity.ALL ) {
			if ( !(ent.isOfType(FloatingItem) || isOfType(FloatingItem))
				&& !(Std.isOfType(ent, Structure) && !(cast(ent, Structure).toBeCollidedAgainst))
				&& ent != this ) {

				for ( collObj in collisions.keys() ) {
					for ( entCollObj in ent.collisions.keys() ) {
						var collideInfo = Collision.shapeWithShape(collObj, entCollObj);
						if ( collideInfo != null ) {
							collided = true;

							collObj.x += (collideInfo.separationX);
							collObj.y += (collideInfo.separationY);

							if ( doMove ) {
								footX += (collideInfo.separationX);
								footY += (collideInfo.separationY);
							}
						}
					}
				}
			}
		}

		for ( poly in Level.inst.walkable ) {
			for ( collObj in collisions.keys() ) {
				var collideInfo = Collision.shapeWithShape(collObj, poly);
				if ( collideInfo != null ) {
					collided = true;

					collObj.x += (collideInfo.separationX);
					collObj.y += (collideInfo.separationY);

					if ( doMove ) {
						footX += (collideInfo.separationX);
						footY += (collideInfo.separationY);
					}
				}
			}
		}
		return collided;
		#else
		return false;
		#end

		// footX = (collisions[0].x);
		// footY = (collisions[0].y);
	}

	public function preUpdate() {
		spr.anim.update(tmod);
		cd.update(tmod);
		tw.update(tmod);
	}

	public function update() {
		#if !headless
		@:privateAccess if (spr.anim.getCurrentAnim() != null) {
			if ( tmpCur != 0 && (spr.anim.getCurrentAnim().curFrameCpt - (tmpDt)) == 0 ) // ANIM LINK HACK
				spr.anim.getCurrentAnim().curFrameCpt = tmpCur + spr.anim.getAnimCursor();
			tmpDt = tmod * spr.anim.getCurrentAnim().speed;
			tmpCur = spr.anim.getCurrentAnim().curFrameCpt;
		}
		// x
		var steps = M.ceil(M.fabs(dxTotal * tmod));
		var step = dxTotal * tmod / steps;

		step = (M.fabs(dy) > 0.0001) ? step * isoCoefficient : step; // ISO FIX

		while( steps > 0 ) {
			xr += step;
			while( xr > 1 ) {
				xr--;
				footX++;
			}
			while( xr < 0 ) {
				xr++;
				footX--;
			}
			steps--;
		}

		dx *= Math.pow(frict, tmod);
		bdx *= Math.pow(bumpFrict, tmod);
		if ( M.fabs(dx) <= 0.0005 * tmod ) dx = 0;
		if ( M.fabs(bdx) <= 0.0005 * tmod ) bdx = 0;

		// y
		var steps = M.ceil(M.fabs(dyTotal * tmod));
		// var step = 0.;

		step = (M.fabs(step) > 0.001) ? (dyTotal * tmod / steps * isoCoefficient * 0.5) : (dyTotal * tmod / steps); // ISO FIX

		while( steps > 0 ) {
			yr += step;
			while( yr > 1 ) {
				yr--;
				footY++;
			}
			while( yr < 0 ) {
				yr++;
				footY--;
			}
			steps--;
		}

		dy *= Math.pow(frict, tmod);
		bdy *= Math.pow(bumpFrict, tmod);
		if ( M.fabs(dy) <= 0.0005 * tmod ) dy = 0;
		if ( M.fabs(bdy) <= 0.0005 * tmod ) bdy = 0;
		#end
	}

	public function postUpdate() {
		#if !headless
		if ( mesh != null ) {
			updateCollisions();
			// spr.scaleX = dir * sprScaleX;
			// spr.scaleY = sprScaleY;

			// if ( !cd.has("colorMaintain") ) {
			// 	colorAdd.r *= Math.pow(0.6, tmod);
			// 	colorAdd.g *= Math.pow(0.6, tmod);
			// 	colorAdd.b *= Math.pow(0.6, tmod);
			// }

			// if (debugLabel != null) {
			// 	debugLabel.x = Std.int(footX - debugLabel.textWidth * 0.5);
			// 	debugLabel.y = Std.int(footY + 1);
			// }
			// curFrame = spr.anim.getCurrentAnim().curFrameCpt;
		}

		if ( !isMoving() ) {
			footX = M.round(M.fabs(footX));
			footY = M.round(M.fabs(footY));
		}
		#end
	}

	public function frameEnd() {
		#if !headless
		if ( mesh != null ) {
			@:privateAccess
			var bounds = mesh.plane.getBounds();

			bounds.xMax = spr.tile.width + footX;
			bounds.xMin = footX;

			var needForDraw = Game.inst.camera.s3dCam.frustum.hasBounds(bounds);

			if ( !needForDraw ) {
				mesh.visible = false;
				spr.visible = false;
			}

			if ( needForDraw ) {
				mesh.visible = true;
				spr.visible = true;

				tex.clear(0, 0);
				spr.x = spr.scaleX > 0 ? -spr.tile.dx : spr.tile.dx + spr.tile.width;
				spr.y = spr.scaleY > 0 ? -spr.tile.dy : spr.tile.dy + spr.tile.height;

				spr.drawTo(tex);
				if ( pivotChanged ) {
					texTile.setCenterRatio(spr.pivot.centerFactorX, spr.pivot.centerFactorY);
					mesh.tile = texTile;
					pivotChanged = false;
				}

				mesh.x = footX;
				mesh.z = footY;
			}
		#end
		}
	}
}
