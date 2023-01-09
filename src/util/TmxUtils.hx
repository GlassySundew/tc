package util;

import dn.M;
import en.Entity;
import format.tmx.Data;
import format.tmx.TmxMap;
import format.tmx.Tools;
import game.client.GameClient;
import game.client.level.LevelView;
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
	var ?tmxTileLayerCb : TmxTileLayer -> Void;
	var ?tmxObjLayerCb : TmxObjectGroup -> Void;
	var ?tmxImgLayerCb : TmxImageLayer -> Void;
	var ?tmxGroupLayerCb : TmxGroup -> Void;
}

class TmxUtils {

	public static function layerRec(
		layer : TmxLayer,
		tmxLayerCb : TmxLayerCb
	) {
		switch( layer ) {
			case LTileLayer( layer ):
				if ( tmxLayerCb.tmxTileLayerCb != null )
					tmxLayerCb.tmxTileLayerCb( layer );
			case LObjectGroup( group ):
				if ( tmxLayerCb.tmxObjLayerCb != null )
					tmxLayerCb.tmxObjLayerCb( group );
			case LImageLayer( layer ):
				if ( tmxLayerCb.tmxImgLayerCb != null )
					tmxLayerCb.tmxImgLayerCb( layer );
			case LGroup( group ):
				if ( tmxLayerCb.tmxGroupLayerCb != null )
					tmxLayerCb.tmxGroupLayerCb( group );

				if ( group.visible )
					for ( grLayer in group.layers )
						layerRec( grLayer, tmxLayerCb );
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
		// если ent не определён, то на все Entity из массива
		// ALL будут добавлены TmxObject из тайлсета с названием colls

		var ents = ent != null ? [ent] : Entity.ServerALL;

		for ( ent in ents ) {
			var tilesetEntityTile = ent.model.tsTile;

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

		var ents = ent != null ? [ent] : Entity.ALL;

		for ( ent in ents ) {
			var center : Vector = ent.clientConfig.center;

			for ( obj in ent.clientConfig.collisions ) {
				var height = obj.properties.getProp( PTFloat, "h", 1, null );

				// polygon
				var verts : Array<Vec3> = [];
				for ( isoVert in obj.points )
					verts.push( new Vec3( isoVert.x, isoVert.y, 0 ) );
				for ( isoVert in obj.points )
					verts.push( new Vec3( isoVert.x, isoVert.y, height ) );

				var sc : ShapeConfig = new ShapeConfig();
				sc.geometry = new ConvexHullGeometry( verts );
				sc.position.init( obj.centerOffset.x, obj.centerOffset.y, 0 );

				var b : RigidBody = ent.model.rigidBody;
				var shape = new Shape( sc );
				if ( b == null ) {
					var bc : RigidBodyConfig = new RigidBodyConfig();
					bc.type = ent.clientConfig.tsTile.properties.getProp(
						PTBool,
						"static",
						DYNAMIC
					) ? STATIC : DYNAMIC;
					b = new RigidBody( bc );
					LevelView.inst.world.addRigidBody( b );
					ent.model.rigidBody = b;
				}
				b.addShape( shape );
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

	public static function getTmxObjTsTile(
		tmxObj : TmxObject,
		tmxMap : TmxMap
	) : TmxTilesetTile {
		switch tmxObj.objectType {
			case OTTile( gid ):
				return Tools.getTileByGid( tmxMap, gid );
			default:
		}
		return null;
	}
}
