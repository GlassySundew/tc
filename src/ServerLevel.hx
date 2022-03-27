/**
	server-side level
**/

import en.Entity;
import hxbit.Serializable;
import differ.math.Vector;
import format.tmx.Data.TmxPoint;
import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxObject;
import format.tmx.Tools;
import differ.shapes.Polygon;
import format.tmx.Data.TmxMap;

class ServerLevel extends dn.Process implements Serializable {
	public var sqlId : Null<Int>;
	@:s public var tmxMap : TmxMap;

	@:s public var walkable : Array<Polygon> = [];
	@:s public var entitiesTmxObj : Array<TmxObject> = [];
	@:s public var entities : Array<Entity> = [];

	public var wid ( get, never ) : Int;

	public var hei ( get, never ) : Int;

	@:s public var lvlName : String;

	inline function get_wid()
		return Std.int ( (Math.min ( tmxMap.height, tmxMap.width ) + Math.abs (-tmxMap.width + tmxMap.height ) / 2) * tmxMap.tileWidth );

	inline function get_hei()
		return Std.int ( (Math.min ( tmxMap.height, tmxMap.width ) + Math.abs (-tmxMap.width + tmxMap.height ) / 2) * tmxMap.tileHeight );

	var layersByName : Map<String, TmxLayer> = new Map ();

	public function new( map : TmxMap ) {
		super ( Server.inst );

		tmxMap = map;

		for ( layer in tmxMap.layers ) {
			var name : String = 'null';
			switch( layer ) {
				case LObjectGroup ( ol ):
					name = ol.name;
					for ( obj in ol.objects ) {
						if ( ol.name == 'obstacles' ) {
							switch( obj.objectType ) {
								case OTPolygon ( points ):
									var pts = makePolyClockwise ( points );
									setWalkable ( obj, pts );
								case OTRectangle:
									setWalkable ( obj );
								default:
							}
						}
						if ( map.orientation == Isometric ) {
							// Если Entity никак не назван на карте - то ему присваивается имя его картинки без расширения
							if ( obj.name == "" ) {
								switch( obj.objectType ) {
									case OTTile ( gid ):
										var objGid = Tools.getTileByGid ( tmxMap, gid );
										if ( objGid != null
											&& eregFileName.match ( objGid.image.source ) ) obj.name = eregFileName.matched ( 1 );
									default:
								}
							}
							if ( ol.name == 'entities' ) {
								switch obj.objectType {
									case OTTile ( gid ):
										Tools.propagateTilePropertiesToObject ( obj, tmxMap, gid );
									default:
								}
								entitiesTmxObj.push ( obj );
							}
						}
					}
				case LTileLayer ( tl ):
					name = tl.name;
				default:
			}
			layersByName.set ( name, layer );
		}
	}

	public inline function cartToIsoLocal( x : Float, y : Float ) : Vector {
		return new Vector (
			-(tmxMap.width - tmxMap.height) / 2 * tmxMap.tileHeight + wid * .5 + cartToIso ( x, y ).x,
			hei - cartToIso ( x, y ).y
		);
	}

	public function setWalkable( poly : TmxObject, ?points : Array<TmxPoint> ) { // setting obstacles as a differ polygon
		var vertices : Array<differ.math.Vector> = [];

		if ( points != null ) {
			makePolyClockwise ( points );
			for ( i in points ) vertices.push ( new differ.math.Vector ( cartToIso ( i.x, i.y ).x, cartToIso ( i.x, i.y ).y ) );
			walkable.push ( new Polygon ( cartToIsoLocal ( poly.x, poly.y ).x, cartToIsoLocal ( poly.x, poly.y ).y, vertices ) );
		} else if ( poly.objectType == OTRectangle ) {
			vertices.push ( new differ.math.Vector ( cartToIso ( poly.width, 0 ).x, cartToIso ( poly.width, 0 ).y ) );
			vertices.push ( new differ.math.Vector ( cartToIso ( poly.width, poly.height ).x, cartToIso ( poly.width, poly.height ).y ) );
			vertices.push ( new differ.math.Vector ( cartToIso ( 0, poly.height ).x, cartToIso ( 0, poly.height ).y ) );
			vertices.push ( new differ.math.Vector ( 0, 0 ) );

			walkable.push ( new Polygon ( cartToIsoLocal ( poly.x, poly.y ).x, cartToIsoLocal ( poly.x, poly.y ).y, vertices ) );
		}
		walkable[walkable.length - 1].scaleY = -1;
	}

	// destroys itself if has no player instances for 5 seconds
	function gc() {
		for ( e in entities ) {}
	}
}
