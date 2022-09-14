package utils;

import oimo.collision.geometry.CylinderGeometry;
import game.client.level.Level;
import h3d.Vector;
import oimo.dynamics.rigidbody.Shape;
import oimo.dynamics.rigidbody.RigidBody;
import oimo.dynamics.rigidbody.RigidBodyConfig;
import oimo.dynamics.rigidbody.ShapeConfig;
import oimo.collision.geometry.ConvexHullGeometry;
import oimo.common.Vec3;
import format.tmx.Data.TmxGroup;
import format.tmx.Data.TmxImageLayer;
import format.tmx.Data.TmxObjectGroup;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxLayer;
import format.tmx.TmxMap;
import format.tmx.Data.TmxTilesetTile;
import format.tmx.Tools;
import game.client.GameClient;

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
		var tmxMap = ent.level.tmxMap;
		if ( tmxMap == null ) return;

		var ents = ent != null ? [ent] : Entity.ServerALL;

		for ( ent in ents ) {
			var tilesetEntityTile = getCorrespondingEntityTsTile( ent, tmxMap );

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
						var cent = getProjPolySize( obj, points, Vector );

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

			var actualX = Std.int( ent.tmxObj.width ) >> 1;
			var actualY = Std.int( ent.tmxObj.height );

			ent.footX.val -= actualX - pivotX;
			ent.footY.val += actualY - pivotY;

			if ( ent.tmxObj.flippedHorizontally ) {
				EntityUtil.flipX( ent );
			}
		}
	}

	/**
		client-side
	**/
	public static function applyTmxObjectOnEntity( ?ent : Null<Entity> ) {
		// если ent не определён, то на все Entity из массива ALL будут добавлены TmxObject из тайлсета с названием colls
		var tmxMap = GameClient.inst.tmxMap;
		if ( tmxMap == null ) return;

		var ents = ent != null ? [ent] : Entity.ALL;

		for ( ent in ents ) {
			var tilesetEntityTile = getCorrespondingEntityTsTile( ent, tmxMap );

			// соотношение, которое в конце будет применено к entity
			var center = new Vector();
			var centerPt = tilesetEntityTile.objectGroup.objects.filter( obj -> obj.name == "center" )[0];
			if ( centerPt != null ) {
				center.x = centerPt.x;
				center.y = centerPt.y;
			}

			for ( obj in tilesetEntityTile.objectGroup.objects ) {
				var height = obj.properties.exists( "h" ) ? obj.properties.getInt( "h" ) : 1;

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
						var pts = makePolyClockwise( points );
						var cent = getProjPolySize( obj, points, Vector );

						if ( center.x == 0 && center.y == 0 ) {
							center.x = cent.x + obj.x;
							center.y = cent.y + obj.y;
						}

						var verts : Array<Vec3> = [];
						for ( i in pts ) verts.push( new Vec3( i.x + obj.x - center.x, ( i.y + obj.y - center.y ) * 1.333333333, 0 ) );
						for ( i in pts ) verts.push( new Vec3( i.x + obj.x - center.x, ( i.y + obj.y - center.y ) * 1.333333333, height ) );

						rotatePoly( obj.rotation - 45, verts );

						var sc : ShapeConfig = new ShapeConfig();
						// sc.position.init( obj.x - center.x, obj.y - center.y, 0 );

						sc.geometry = new ConvexHullGeometry( verts );

						var b : RigidBody = ent.rigidBody;
						var shape = new Shape( sc );

						if ( b == null ) {
							var bc : RigidBodyConfig = new RigidBodyConfig();
							b = new RigidBody( bc );
							Level.inst.world.addRigidBody( b );
							ent.rigidBody = b;
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

	private static function getCorrespondingEntityTsTile( ent : Entity, tmxMap : TmxMap ) : TmxTilesetTile {
		switch ent.tmxObj.objectType {
			case OTTile( gid ):
				return Tools.getTileByGid( tmxMap, gid );
			default:
		}
		return null;
	}
}
