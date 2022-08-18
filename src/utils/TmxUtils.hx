package utils;

import format.tmx.Data.TmxGroup;
import format.tmx.Data.TmxImageLayer;
import format.tmx.Data.TmxObjectGroup;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxLayer;
import format.tmx.TmxMap;
import differ.math.Vector;
import differ.shapes.Polygon;
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
						var shape = new differ.shapes.Circle( 0, 0, obj.width / 2 );
						var cent = new Vector(
							obj.width / 2,
							obj.height / 2
						);

						ent.collisions.set( shape, new differ.math.Vector( obj.x + cent.x, obj.y + cent.y ) );

						if ( center.x == 0 && center.y == 0 ) {
							center.x = cent.x + obj.x;
							center.y = cent.y + obj.y;
						}
					case OTPoint:
						switch obj.name {
							case "center":
								center.x = obj.x;
								center.y = obj.y;
						}
					case OTPolygon( points ):
						var cent = getProjectedDifferPolygonRect( obj, points );

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

			ent.pivot = { x : pivotX, y : pivotY };

			var actualX = Std.int( ent.tmxObj.width ) >> 1;
			var actualY = Std.int( ent.tmxObj.height );

			ent.footX.val -= actualX - pivotX;
			ent.footY.val += actualY - pivotY;

			if ( ent.tmxObj.flippedHorizontally ) {
				ent.flipX();
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

			for ( obj in tilesetEntityTile.objectGroup.objects ) {
				switch obj.objectType {
					case OTRectangle:
					case OTEllipse:
						var shape = new differ.shapes.Circle( 0, 0, obj.width / 2 );
						var cent = new Vector(
							obj.width / 2,
							obj.height / 2
						);

						ent.collisions.set( shape, new differ.math.Vector( obj.x + cent.x, obj.y + cent.y ) );

						if ( center.x == 0 && center.y == 0 ) {
							center.x = cent.x + obj.x;
							center.y = cent.y + obj.y;
						}
					case OTPoint:
						switch obj.name {
							case "center":
								center.x = obj.x;
								center.y = obj.y;
						}
					case OTPolygon( points ):
						var pts = makePolyClockwise( points );
						rotatePoly( obj, pts );

						var cent = getProjectedDifferPolygonRect( obj, points );

						var verts : Array<Vector> = [];
						for ( i in pts ) verts.push( new Vector( i.x, i.y ) );

						var poly = new Polygon( 0, 0, verts );

						poly.scaleY = -1;
						ent.collisions.set(
							poly,
							new differ.math.Vector( obj.x, obj.y )
						);

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

			ent.pivot = { x : pivotX, y : pivotY };

			#if depth_debug
			if ( ent.mesh != null )
				ent.mesh.renewDebugPts();
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
