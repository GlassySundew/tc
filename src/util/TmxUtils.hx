package util;

import dn.M;
import en.Entity;
import format.tmx.Data.TmxGroup;
import format.tmx.Data.TmxImageLayer;
import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxObjectGroup;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxTilesetTile;
import format.tmx.TmxMap;
import format.tmx.Tools;
import game.client.GameClient;
import game.client.level.Level;
import h2d.col.Point;
import h3d.Vector;
import oimo.collision.geometry.ConvexHullGeometry;
import oimo.common.Vec3;
import oimo.dynamics.rigidbody.RigidBody;
import oimo.dynamics.rigidbody.RigidBodyConfig;
import oimo.dynamics.rigidbody.RigidBodyType.*;
import oimo.dynamics.rigidbody.Shape;
import oimo.dynamics.rigidbody.ShapeConfig;

using util.Extensions.TmxPropertiesExtension;
using en.util.EntityUtil;

typedef TmxLayerCb = {
	var ?tmxTileLayerCb : TmxTileLayer -> Bool;
	var ?tmxObjLayerCb : TmxObjectGroup -> Bool;
	var ?tmxImgLayerCb : TmxImageLayer -> Bool;
	var ?tmxGroupLayerCb : TmxGroup -> Bool;
}

class TmxUtils {

	public static function layerRec(
		layer : TmxLayer,
		tmxLayerCb : TmxLayerCb
	) {
		switch( layer ) {
			case LTileLayer( layer ):
				if ( tmxLayerCb.tmxTileLayerCb != null && !tmxLayerCb.tmxTileLayerCb( layer ) ) return;
			case LObjectGroup( group ):
				if ( tmxLayerCb.tmxObjLayerCb != null && !tmxLayerCb.tmxObjLayerCb( group ) ) return;
			case LImageLayer( layer ):
				if ( tmxLayerCb.tmxImgLayerCb != null && !tmxLayerCb.tmxImgLayerCb( layer ) ) return;
			case LGroup( group ):
				if ( tmxLayerCb.tmxGroupLayerCb != null && !tmxLayerCb.tmxGroupLayerCb( group ) ) return;

				if ( group.visible )
					for ( grLayer in group.layers ) {
						var tmxLayerArg : TmxLayer = switch grLayer {
							case LTileLayer( layer ): LTileLayer( layer );
							case LObjectGroup( group ): LObjectGroup( group );
							case LImageLayer( layer ): LImageLayer( layer );
							case LGroup( group ): LGroup( group );
						}
						layerRec( tmxLayerArg, tmxLayerCb );
					}
		}
	}

	public static function mapTmxMap(
		tmxMap : TmxMap,
		tmxLayerCb : TmxLayerCb
	) {
		for ( l in tmxMap.layers ) layerRec( l, tmxLayerCb );
	}

	public static function isMap3d( tmxMap : TmxMap ) {
		return tmxMap.properties.getBool( "3d" );
	}

	/**
		server-side
	**/
	public static function calculateCoordinateOffset( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		var tmxMap = ent.model.level.tmxMap;
		if ( tmxMap == null ) return;

		var ents = ent != null ? [ent] : Entity.ServerALL;

		for ( ent in ents ) {
			var tilesetEntityTile = getEntityTsTile( ent, tmxMap );

			// соотношение, которое в конце будет применено к entity
			var center = new Vector();

			for ( obj in tilesetEntityTile.objectGroup.objects ) {
				switch obj.objectType {
					case OTRectangle:
					case OTEllipse:
					// var shape = new differ.shapes.Circle( 0, 0, obj.width / 2 );
					// var cent = new Vector(
					// 	obj.width / 2,
					// 	obj.height / 2
					// );

					// if ( center.x == 0 && center.y == 0 ) {
					// 	center.x = cent.x + obj.x;
					// 	center.y = cent.y + obj.y;
					// }
					case OTPoint:
						switch obj.name {
							case "center":
								center.x = obj.x;
								center.y = obj.y;
						}
					case OTPolygon( points ):
						var cent = Util.getProjPolySize( points, Vector );

						if ( center.x == 0 && center.y == 0 ) {
							center.x = cent.x + obj.x;
							center.y = cent.y + obj.y;
						}

					default:
				}
			}

			// ending serving this particular entity 'ent' here
			var pivotX = center.x;
			var pivotY = center.y;

			var centerOffsetX : Float = ent.model.tmxObj.width / 2 - pivotX;
			var centerOffsetY = ( ent.model.tmxObj.height - pivotY ) * 2;

			var isoOff = Util.cartToIso( centerOffsetX, centerOffsetY );

			ent.model.footX.val -= isoOff.x / 2;
			ent.model.footY.val += isoOff.y / 2;

			if ( ent.model.tmxObj.flippedHorizontally ) {
				ent.flipX();
			}

			ent.setFeetPos(
				ent.model.footX.val,
				ent.model.footY.val,
				ent.model.footZ.val
			);
		}
	}

	/**
		client-side
	**/
	public static function applyTmxObjectOnEntity( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		var tmxMap = GameClient.inst.tmxMap;
		if ( tmxMap == null ) {
			trace( 'failed to apply tmx object, tmx map of GameClient.inst.level was not loaded' );
			return;
		}

		var ents = ent != null ? [ent] : Entity.ALL;

		for ( ent in ents ) {
			var center : Vector = ent.clientConfig.center;

			for ( obj in ent.clientConfig.collisions ) {
				var height = obj.properties.getProp( PTFloat, "h", 1, null );

				switch obj.objectType {
					case OTRectangle:
					case OTEllipse:
					// var sc : ShapeConfig = new ShapeConfig();
					// sc.geometry = new CylinderGeometry( obj.width / 2, height / 2 );

					// var bc : RigidBodyConfig = new RigidBodyConfig();
					// var b : RigidBody = new RigidBody( bc );
					// var shape = new Shape( sc );

					// b.addShape( shape );

					case OTPolygon( points ):
						var pts = Util.makePolyClockwise( points );

						var isoVerts : Array<Point> = [];
						for ( pt in pts ) {
							var isoPt = Util.cartToIso( pt.x, -pt.y );
							isoPt = Util.isoToCart( isoPt.x, isoPt.y );
							isoVerts.push( new Point( M.round( isoPt.x ), M.round( isoPt.y ) ) );
						}

						var cent = Util.getProjPolySize( isoVerts, Vector );

						if ( center == null ) {
							center = new Vector( cent.x + obj.x, cent.y + obj.y );
						}

						Util.rotatePoly( obj.rotation - 135, isoVerts );

						var verts : Array<Vec3> = [];
						for ( isoVert in isoVerts ) verts.push( new Vec3( isoVert.x, isoVert.y, 0 ) );
						for ( isoVert in isoVerts ) verts.push( new Vec3( isoVert.x, isoVert.y, height ) );

						var isoOffset = Util.cartToIso( center.x - obj.x, -center.y + obj.y );
						isoOffset = Util.isoToCart( isoOffset.x, isoOffset.y );
						Util.rotatePoly( 45, [isoOffset] );

						var sc : ShapeConfig = new ShapeConfig();
						sc.geometry = new ConvexHullGeometry( verts );
						sc.position.init( isoOffset.x, isoOffset.y, 0 );

						var b : RigidBody = ent.model.rigidBody;
						var shape = new Shape( sc );
						if ( b == null ) {
							var bc : RigidBodyConfig = new RigidBodyConfig();
							bc.type = ent.clientConfig.tsTile.properties.getProp( PTBool, "static", DYNAMIC ) ? STATIC : DYNAMIC;
							b = new RigidBody( bc );
							Level.inst.world.addRigidBody( b );
							ent.model.rigidBody = b;
						}
						b.addShape( shape );

					default:
				}
			}

			var pivotX = center.x;
			var pivotY = center.y;

			ent.eSpr.pivot = { x : pivotX, y : pivotY };

			#if depth_debug
			if ( ent.eSpr.mesh != null ) ent.eSpr.mesh.renewDebugPts();
			#end

			try {
				cast( ent, en.InteractableEntity ).rebuildInteract();
			}
			catch( e : Dynamic ) {}
		}
	}

	public static function getEntityTsTile( ent : Entity, tmxMap : TmxMap ) : TmxTilesetTile {
		switch ent.model.tmxObj.objectType {
			case OTTile( gid ):
				return Tools.getTileByGid( tmxMap, gid );
			default:
		}
		return null;
	}
}
