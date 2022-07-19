package en;

import hxbit.NetworkHost;
import net.ClientController;
import differ.Collision;
import differ.shapes.Circle;
import differ.shapes.Polygon;
import differ.shapes.Shape;
import dn.heaps.slib.HSprite;
import en.objs.IsoTileSpr;
import format.tmx.Data.TmxObject;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import h3d.scene.Mesh;
import h3d.scene.Object;
import h3d.scene.Sphere;
import hxGeomAlgo.HxPoint;
import hxGeomAlgo.PoleOfInaccessibility;
import hxbit.NetworkSerializable;
import hxd.IndexBuffer;
import net.ClientToServer.AClientToServerFloat;
import tools.Save;
import ui.InventoryGrid;

class Entity implements NetworkSerializable {

	public static var ALL : Array<Entity> = [];
	public static var ServerALL : Array<Entity> = [];

	public static var GC : Array<Entity> = [];

	/**
		Map of multiple shapes, 1st vector is a center of polygon Shape, 2nd polygon is a position of a poly
	**/
	public var collisions : Map<Shape, differ.math.Vector>;

	@:s public var level( default, set ) : ServerLevel;

	function set_level( v : ServerLevel ) {
		return level = v;
	}

	public var destroyed( default, null ) = false;
	public var tmod( get, never ) : Float;

	public var xr = 0.5;
	public var yr = 0.5;
	public var zr = 0.;

	public var dx = 0.;

	public var dy = 0.;

	public var dz = 0.;
	public var bdx = 0.;
	public var bdy = 0.;

	public var dxTotal( get, never ) : Float;

	inline function get_dxTotal() return dx + bdx;

	public var dyTotal( get, never ) : Float;

	inline function get_dyTotal() return dy + bdy;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var bumpReduction = 0.;

	@:s public var dir( default, set ) : AClientToServerFloat;

	inline function get_tmod() {
		return #if headless GameServer.inst.tmod #else if ( GameClient.inst != null ) GameClient.inst.tmod else
			Client.inst.tmod #end;
	}

	@:s
	public var footX : AClientToServerFloat;

	@:s
	public var footY : AClientToServerFloat;

	// public var tmxTile( get, never ) : TmxTilesetTile;
	// inline function get_tmxTile() return Tools.getTileByGid( Level.inst.data, tmxObj.objectType.getParameters()[0] );
	public var sqlId : Null<Int>;

	@:s
	public var tmxObj : TmxObject;
	public var colorAdd : h3d.Vector;
	public var spr : HSprite;
	public var mesh : IsoTileSpr;
	public var meshDefaultRotation : Vector;
	public var tmpDt : Float;
	public var tmpCur : Float;
	public var curFrame : Float = 0;

	public var sprFrame : { group : String, frame : Int };

	private var rotAngle : Float = -0.01;
	private var tex : Texture;
	private var texTile : Tile;

	public var cd : dn.Cooldown;
	public var tw : Tweenie;
	@:s
	public var flippedX : Bool;
	public var pivotChanged = true;

	/** 
		реальный x и y центра у спрайта, не процент
	**/
	public var pivot : { x : Float, y : Float };

	public static var isoCoefficient = 1.2;

	public var cellGrid : UICellGrid;
	@:s
	public var inventory : InventoryGrid;

	/** 
		из-за того, что метод отрисовки, который я добавил в том виде, какой он есть 
		(тайл из spr просто передаётся в mesh ), всякие эффекты и шейдеры не будут 
		работать если forceDrawTo не будет true (спрайт будет рисоваться через spr.drawTo())
	**/
	public var forceDrawTo : Bool = false;
	public var refreshTile : Bool = false;

	var flippedOnClient = false;
	private var tmxAppliedInvalidate = false;

	public function new( ?x : Float = 0, ?z : Float = 0, ?tmxObj : Null<TmxObject>, ?tmxGId : Null<Int> ) {
		ServerALL.push( this );

		pivot = { x : 0, y : 0 };
		footX = new AClientToServerFloat( x, () -> false );
		footY = new AClientToServerFloat( z, () -> false );
		dir = new AClientToServerFloat( 6, () -> false );

		flippedX = false;
		if ( this.tmxObj == null && tmxObj != null ) {
			this.tmxObj = tmxObj;
		}

		serverApplyTmx();

		init( x, z, tmxObj );

		if ( tmxObj != null && tmxObj.flippedHorizontally ) {
			flipX();
		}
	}

	function replicate() {
		enableAutoReplication = true;
	}

	public function init( ?x : Float, ?z : Float, ?tmxObj : Null<TmxObject> ) {
		replicate();
		cd = new dn.Cooldown( Const.FPS );
	}

	var debugObjs : Array<Object> = [];

	/** update debug centers and colliders poly**/
	public function updateDebugDisplay() {

		for ( i in debugObjs ) if ( i != null ) i.remove();
		debugObjs = [];

		#if entity_centers_debug
		var sphere = new Sphere( 0x361bcc, 1, false, mesh );
		sphere.material.mainPass.wireframe = true;
		sphere.material.shadows = false;
		sphere.material.mainPass.depth( true, Less );
		sphere.x = 0.25;
		debugObjs.push( sphere );
		#end

		#if colliders_debug
		GameClient.inst.delayer.addF(() -> {
			if ( collisions != null )
				for ( shape => vec in collisions ) {
					switch true {
						case Std.isOfType( shape, Polygon ) => a if ( a ):
							var pts : Array<h3d.col.Point> = [];

							var poly = cast( shape, Polygon );

							if ( poly.vertices == null ) continue;
							for ( pt in poly.vertices ) {
								pts.push( new h3d.col.Point( pt.x, 0, pt.y ) );
							}
							var idx = new IndexBuffer();
							for ( i in 1...pts.length - 1 ) {
								idx.push( 0 );
								idx.push( i );
								idx.push( i + 1 );
							}

							var polyPrim = new h3d.prim.Polygon( pts, idx );
							polyPrim.addUVs();
							polyPrim.addNormals();

							var isoDebugMesh = new Mesh( polyPrim, mesh );
							// isoDebugMesh.rotate(0, M.toRad(180), M.toRad(90));
							isoDebugMesh.material.color.setColor( 0x361bcc );
							isoDebugMesh.material.shadows = false;
							isoDebugMesh.material.mainPass.wireframe = true;
							isoDebugMesh.material.mainPass.depth( true, Less );

							isoDebugMesh.x = 0.5;
							isoDebugMesh.y = ( spr.pivot.centerFactorX * tmxObj.width )
								- vec.x;
							isoDebugMesh.z = ( spr.pivot.centerFactorY * tmxObj.height )
								- vec.y;

							isoDebugMesh.rotate( M.toRad( poly.rotation ), 0, -M.toRad( 90 ) );
							isoDebugMesh.scaleX = poly.scaleX;
							isoDebugMesh.scaleZ = poly.scaleY;

							debugObjs.push( isoDebugMesh );

						// isoDebugMesh.z = shape.y;
						case Std.isOfType( shape, Circle ) => a if ( a ):
							var circle = cast( shape, Circle );

							var sphere = new Sphere( 0x361bcc, circle.radius, false, mesh );
							sphere.material.mainPass.wireframe = true;
							sphere.material.shadows = false;
							sphere.material.mainPass.depth( true, Less );
							sphere.scaleZ = circle.scaleY;

							sphere.x = .25;
							sphere.y = ( spr.pivot.centerFactorX * tmxObj.width )
								- vec.x;
							sphere.z = ( spr.pivot.centerFactorY * tmxObj.height )
								- vec.y;

							debugObjs.push( sphere );
					}
				}
		}, 3 );
		#end
	}

	/**
		called only on client-side when replicating entity over network on client side
	**/
	public function alive() {
		init();
		trace( "aliving entity " + this );

		pivot = { x : 0, y : 0 };
		collisions = new Map<Shape, differ.math.Vector>();

		ALL.push( this );
		tw = new Tweenie( Const.FPS );

		if ( spr == null ) throw "spr hasnt been initialised in " + this;

		if ( spr.groupName == null && sprFrame != null && sprFrame.group != "null" ) {
			spr.set( sprFrame.group, sprFrame.frame );
		}

		setPivot();

		colorAdd = new h3d.Vector();
		spr.colorAdd = colorAdd;

		tex = new Texture( Std.int( spr.tile.width ), Std.int( spr.tile.height ), [Target] );

		spr.x = spr.scaleX > 0 ? -spr.tile.dx : spr.tile.dx + spr.tile.width;
		spr.y = spr.scaleY > 0 ? -spr.tile.dy : spr.tile.dy + spr.tile.height;

		spr.tile.getTexture().filter = Nearest;
		spr.blendMode = Alpha;
		spr.drawTo( tex );

		texTile = Tile.fromTexture( tex );
		texTile.getTexture().filter = Nearest;

		mesh = new IsoTileSpr( texTile, false, Boot.inst.s3d );

		mesh.material.mainPass.setBlendMode( Alpha );

		meshDefaultRotation = new Vector( tmxObj != null ? M.toRad( tmxObj.rotation ) : 0, -rotAngle, M.toRad( 90 ) );
		mesh.rotate( meshDefaultRotation.x, meshDefaultRotation.y, meshDefaultRotation.z );
		var s = mesh.material.mainPass.addShader( new h3d.shader.ColorAdd() );
		s.color = colorAdd;
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.depth( false, Less );

		// TODO semi-transparent shadow overlapping
		// var s = new h3d.mat.Stencil();
		// s.setFunc(LessEqual, 0);
		// s.setOp(Keep, DecrementWrap, Keep);
		// mesh.material.mainPass.stencil = s;

		if ( tmxObj != null && tmxObj.flippedVertically ) spr.scaleY = -1;

		GameClient.inst.delayer.addF(() -> {
			#if debug
			updateDebugDisplay();
			#end

			function applyTmx() {
				// ждём пока придёт уровень с сервера
				clientApplyTmx();
				if ( flippedX ) {
					if ( !flippedOnClient ) clientFlipX();
				}
			}

			if ( Main.inst.clientController.level == null ) {
				GameClient.inst.onLevelChanged.add( applyTmx, true );
			} else applyTmx();
		}, 1 );
	}

	public function isOfType<T : Entity>( c : Class<T> ) return Std.isOfType( this, c );

	public function as<T : Entity>( c : Class<T> ) : T return Std.downcast( this, c );

	public inline function angTo( e : Entity )
		return Math.atan2( e.footY.toFloat() - footY.toFloat(), e.footX.toFloat() - footX.toFloat() );

	public inline function angToPxFree( x : Float, y : Float )
		return Math.atan2( y - footY.toFloat(), x - footX.toFloat() );

	public function blink( ?c = 0xffffff ) {
		colorAdd.setColor( c );
		cd.setS( "colorMaintain", 0.03 );
	}

	// @:s
	public var isMoving( get, never ) : Bool;

	function get_isMoving() return M.fabs( dxTotal ) >= 0.01 || M.fabs( dyTotal ) >= 0.01;

	public inline function at( x, y ) return footX == x && footY == y;

	public inline function isAlive() {
		return !destroyed; // && life > 0;
	}

	public function isLocked() return cd == null ? true : cd.has( "lock" );

	@:rpc
	public function lock( ?ms : Float ) {
		cd.setMs( "lock", ms != null ? ms : 1 / 0 );
	}

	@:rpc
	public function unlock() if ( cd != null ) cd.unset( "lock" );

	public function setPivot() {
		pivotChanged = true;

		if ( spr != null )
			spr.pivot.setCenterRatio( pivot.x / tmxObj.width, pivot.y / tmxObj.height );
	}

	public function serverApplyTmx() {
		if ( GameServer.inst != null )
			GameServer.inst.calculateCoordinateOffset( this );
	}

	public function clientApplyTmx() {
		if ( GameClient.inst != null ) {
			GameClient.inst.applyTmxObjOnEnt( this );
			tmxAppliedInvalidate = true;
			setPivot();
		}
	}

	public function dropItem( item : en.Item, ?angle : Float, ?power : Float ) : en.Item {
		angle = angle == null ? Math.random() * M.toRad( 360 ) : angle;
		power = power == null ? Math.random() * .04 * 48 + .01 : power;

		var fItem = new FloatingItem( footX, footY, item );
		fItem.bump( Math.cos( angle ) * power, Math.sin( angle ) * power, 0 );
		fItem.lock( 1000 );
		if ( item.itemSprite != null )
			item.itemSprite.remove();

		return item;
	}

	inline function set_dir( v ) {
		if ( dir != v ) {
			// spr.anim.getCurrentAnim().curFrameCpt = curFrame;
		}

		return dir = v;
	}

	/** Flips spr.scaleX, all of collision objects, and sorting rectangle **/
	public function flipX() {
		flippedX = !flippedX;

		footX += ( ( ( 1 - pivot.x / tmxObj.width * 2 ) * tmxObj.width ) );

		clientFlipX();
	}

	@:rpc( clients )
	function clientFlipX() {

		if ( !tmxAppliedInvalidate ) return;

		pivot.x = tmxObj.width - pivot.x;
		setPivot();

		for ( shape => offset in collisions ) {
			shape.scaleX *= -1;
			offset.x *= -1;
			offset.x += tmxObj.width;
		}
		spr.scaleX *= -1;

		if ( mesh.isLong ) mesh.flipX();
		mesh.renewDebugPts();
		refreshTile = true;
		flippedOnClient = flippedX;
		Main.inst.delayer.addF(() -> {
			updateDebugDisplay();
		}, 10 );
	}

	public inline function bumpAwayFrom( e : Entity, spd : Float, ?spdZ = 0., ?ignoreReduction = false ) {
		var a = e.angTo( this );
		bump( Math.cos( a ) * spd, Math.sin( a ) * spd, spdZ, ignoreReduction );
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
		return M.dist( footX, footY, e.footX, e.footY );
	}

	/**
		подразумевается, что у этой сущности есть длинный изометрический меш
	**/
	public function distPolyToPt( e : Entity ) {
		if ( mesh == null || !mesh.isLong ) return distPx( e ); else {

			var verts = mesh.getIsoVerts();

			var pt1 = new HxPoint( footX.toFloat() + mesh.xOff + verts.up.x, footY.toFloat() + mesh.yOff + verts.up.y );
			var pt2 = new HxPoint( footX.toFloat() + mesh.xOff + verts.right.x, footY.toFloat() + mesh.yOff + verts.right.y );
			var pt3 = new HxPoint( footX.toFloat() + mesh.xOff + verts.down.x, footY.toFloat() + mesh.yOff + verts.down.y );
			var pt4 = new HxPoint( footX.toFloat() + mesh.xOff + verts.left.x, footY.toFloat() + mesh.yOff + verts.left.y );

			var dist = PoleOfInaccessibility.pointToPolygonDist( e.footX, e.footY, [[pt1, pt2, pt3, pt4]] );
			return -dist;
		}
	}

	public inline function distPxFree( x : Float, y : Float ) {
		return M.dist( footX, footY, x, y );
	}

	public function destroy() {
		if ( !destroyed ) {
			destroyed = true;
			GC.push( this );
		}
	}

	@:keep
	public function customSerialize( ctx : hxbit.Serializer ) {
		// // Data.Item inventory
		// if ( cellGrid != null ) {
		// 	ctx.addInt(cellGrid.grid.length);
		// 	ctx.addInt(cellGrid.grid[0].length);
		// 	ctx.addInt(cellGrid.cellWidth);
		// 	ctx.addInt(cellGrid.cellHeight);
		// 	for ( i in cellGrid.grid ) for ( j in i ) {
		// 		if ( j.item != null ) {
		// 			ctx.addString(Std.string(j.item.cdbEntry));
		// 			ctx.addInt(j.item.amount);
		// 		} else {
		// 			ctx.addString("null");
		// 			ctx.addInt(0);
		// 		}
		// 	}
		// } else {
		// 	ctx.addInt(0);
		// 	ctx.addInt(0);
		// }
	}

	@:keep
	public function customUnserialize( ctx : hxbit.Serializer ) {

		// var invHeight = ctx.getInt();
		// var invWidth = ctx.getInt();
		// if ( cellGrid == null && invHeight > 0 && invWidth > 0 ) {
		// 	var cellWidth = ctx.getInt();
		// 	var cellHeight = ctx.getInt();
		// 	cellGrid = new CellGrid(invWidth, invHeight, cellWidth, cellHeight, this);
		// }
		// for ( i in 0...invHeight ) for ( j in 0...invWidth ) {
		// 	var itemString = ctx.getString();
		// 	var itemAmount = ctx.getInt();
		// 	if ( itemString != "null" && itemString != "null" && itemString != null ) {
		// 		GameClient.inst.delayer.addF(() -> {
		// 			var item = Item.fromCdbEntry(Data.item.resolve(itemString).id, itemAmount);
		// 			item.containerEntity = this;
		// 			cellGrid.grid[i][j].item = item;
		// 		}, 1);
		// 	}
		// }
	}

	public function dispose() {
		ALL.remove( this );
		spr.remove();

		if ( mesh != null ) {
			mesh.tile.dispose();
			mesh.primitive.dispose();
			mesh.remove();
		}

		if ( GameClient.inst != null ) {
			cd.destroy();
			tex.dispose();
			tw.destroy();
		}

		if ( collisions != null ) for ( i in collisions.keys() ) if ( i != null ) i.destroy();
	}

	public function setFeetPos( x : Float, y : Float ) {
		footX.setValue( x );
		footY.setValue( y );
	}

	public function offsetFootByCenter() {
		footX += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		footY -= ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by blueprints, to preview entities
	public function offsetFootByCenterReversed() {
		footX -= ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		footY += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by save manager, when saved objects are already offset by center
	public function offsetFootByCenterXReversed() {
		footX += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		footY += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	public function kill( by : Null<Entity> ) {
		Save.inst.removeEntityById( sqlId );
		destroy();
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer ) @:privateAccess {
		host.unregister( this, ctx );
		host.unregister( footX, ctx );
		host.unregister( footY, ctx );
		host.unregister( dir, ctx );
	}

	public function updateCollisions() {
		if ( collisions != null ) {
			for ( collObj => offset in collisions ) {
				if ( offset != null ) {
					collObj.x = footX.toFloat()
						- pivot.x
						+ offset.x;

					collObj.y = footY.toFloat()
						+ pivot.y
						- offset.y;
				}
			}
		}
	}

	public function checkCollsAgainstAll( ?doMove : Bool = true ) : Bool {
		var collided = false;
		if ( collisions != null ) {

			for ( ent in Entity.ALL ) {
				if (
					ent.collisions != null
					&& !( ent.isOfType( FloatingItem ) || isOfType( FloatingItem ) )
					&& !( Std.isOfType( ent, Structure ) && !( cast( ent, Structure ).toBeCollidedAgainst ) )
					&& ent != this
				) {

					for ( collObj in collisions.keys() ) {
						for ( entCollObj in ent.collisions.keys() ) {
							var collideInfo = Collision.shapeWithShape( collObj, entCollObj );
							if ( collideInfo != null ) {
								collided = true;

								collObj.x += ( collideInfo.separationX );
								collObj.y += ( collideInfo.separationY );

								if ( doMove ) {
									footX += ( collideInfo.separationX );
									footY += ( collideInfo.separationY );
								}
							}
						}
					}
				}
			}

			if ( Level.inst != null )
				for ( poly in Level.inst.walkable ) {
					for ( collObj in collisions.keys() ) {
						var collideInfo = Collision.shapeWithShape( collObj, poly );
						if ( collideInfo != null ) {
							collided = true;

							collObj.x += ( collideInfo.separationX );
							collObj.y += ( collideInfo.separationY );

							if ( doMove ) {
								footX += ( collideInfo.separationX );
								footY += ( collideInfo.separationY );
							}
						}
					}
				}
		}
		return collided;
	}

	private function calculateIsMoving() {
		// isMoving = M.fabs( dxTotal ) >= 0.01 || M.fabs( dyTotal ) >= 0.01;
	}

	public function headlessPreUpdate() {}

	public function headlessUpdate() {}

	public function headlessPostUpdate() {}

	public function headlessFrameEnd() {}

	public function preUpdate() {
		calculateIsMoving();
		spr.anim.update( tmod );
		cd.update( tmod );
		tw.update( tmod );
	}

	public function update() {
		// @:privateAccess if (spr.anim.getCurrentAnim() != null) {
		// 	if ( tmpCur != 0 && (spr.anim.getCurrentAnim().curFrameCpt - (tmpDt)) == 0 ) // ANIM LINK HACK
		// 		spr.anim.getCurrentAnim().curFrameCpt = tmpCur + spr.anim.getAnimCursor();
		// 	tmpDt = tmod * spr.anim.getCurrentAnim().speed;
		// 	tmpCur = spr.anim.getCurrentAnim().curFrameCpt;
		// }

		var steps = M.ceil( M.fabs( dxTotal * tmod ) );
		var step = dxTotal * tmod / steps;

		// if ( networkAllow( SetField, networkPropFootX.toInt(), Player.inst.clientController ) ) {
		// x

		step = ( M.fabs( dy ) > 0.0001 ) ? step * isoCoefficient : step; // ISO FIX

		while( steps > 0 ) {
			xr += step;
			while( xr > 1 ) {
				xr--;
				footX += 1;
			}
			while( xr < 0 ) {
				xr++;
				footX -= 1;
			}
			steps--;
		}

		dx *= Math.pow( frict, tmod );
		bdx *= Math.pow( bumpFrict, tmod );
		if ( M.fabs( dx ) <= 0.0005 * tmod ) dx = 0;
		if ( M.fabs( bdx ) <= 0.0005 * tmod ) bdx = 0;
		// }

		// if ( networkAllow( SetField, networkPropFootY.toInt(), Player.inst.clientController ) ) {
		// y
		var steps = M.ceil( M.fabs( dyTotal * tmod ) );
		step = ( M.fabs( step ) > 0.001 ) ? ( dyTotal * tmod / steps * isoCoefficient * 0.5 ) : ( dyTotal * tmod / steps ); // ISO FIX

		while( steps > 0 ) {
			yr += step;
			while( yr > 1 ) {
				yr--;
				footY += 1;
			}
			while( yr < 0 ) {
				yr++;
				footY -= 1;
			}
			steps--;
		}

		dy *= Math.pow( frict, tmod );
		bdy *= Math.pow( bumpFrict, tmod );
		if ( M.fabs( dy ) <= 0.0005 * tmod ) dy = 0;
		if ( M.fabs( bdy ) <= 0.0005 * tmod ) bdy = 0;
		// }
	}

	public function postUpdate() {
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

		// if ( !isMoving ) {
		// 	footX = M.round( M.fabs( footX ) );
		// 	footY = M.round( M.fabs( footY ) );
		// }
	}

	public function frameEnd() {
		if ( mesh != null && spr != null && spr.tile != null ) {
			@:privateAccess
			var bounds = mesh.plane.getBounds();

			bounds.xMax = spr.tile.width + footX.toFloat();
			bounds.xMin = footX.toFloat();

			var needForDraw = GameClient.inst.camera.s3dCam.frustum.hasBounds( bounds );

			if ( !needForDraw ) {
				mesh.culled = true;
				mesh.visible = false;
				spr.visible = false;
			}

			if ( needForDraw ) {
				mesh.culled = false;
				mesh.visible = true;
				spr.visible = true;

				if ( pivotChanged ) {
					spr.x = spr.scaleX > 0 ? -spr.tile.dx : spr.tile.dx + spr.tile.width;
					spr.y = spr.scaleY > 0 ? -spr.tile.dy : spr.tile.dy + spr.tile.height;

					pivotChanged = false;
					refreshTile = true;
				}

				if ( forceDrawTo ) {
					tex.clear( 0, 0 );
					spr.drawTo( tex );
					texTile.setCenterRatio( spr.pivot.centerFactorX, spr.pivot.centerFactorY );
					mesh.tile = texTile;
				}
				else
					@:privateAccess {
					if ( refreshTile
						|| ( spr.tile.u != mesh.plane.u0 && spr.tile.u != mesh.plane.u1 )
						|| ( spr.tile.u2 != mesh.plane.u1 && spr.tile.u2 != mesh.plane.u0 )
						|| spr.tile.v != mesh.plane.v0
						|| spr.tile.v2 != mesh.plane.v1 ) {

						mesh.tile = spr.tile;
						if ( flippedX ) {

							var tmp = mesh.plane.u1;
							mesh.plane.u1 = mesh.plane.u0;
							mesh.plane.u0 = tmp;
							mesh.plane.invalidate();
						}

						refreshTile = false;
					}
				}

				mesh.x = footX;
				mesh.z = footY;
			}
		}
	}
}
