package game.server;

/**
	server-side level
**/
import dn.Process;
import en.Entity;
import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxObject;
import format.tmx.TmxMap;
import format.tmx.Tools;
import hxbit.NetworkSerializable;

class ServerLevel extends dn.Process implements NetworkSerializable {

	public var sqlId : Null<Int>;
	@:s public var tmxMap : TmxMap;

	@:s public var entitiesTmxObj : Array<TmxObject> = [];
	@:s public var entities : Array<Entity> = [];

	public var wid( get, never ) : Int;

	public var hei( get, never ) : Int;

	@:s public var lvlName : String;

	inline function get_wid()
		return Std.int( ( Math.min( tmxMap.height, tmxMap.width ) + Math.abs(-tmxMap.width + tmxMap.height ) / 2 ) * tmxMap.tileWidth );

	inline function get_hei()
		return Std.int( ( Math.min( tmxMap.height, tmxMap.width ) + Math.abs(-tmxMap.width + tmxMap.height ) / 2 ) * tmxMap.tileHeight );

	var layersByName : Map<String, TmxLayer> = new Map();

	public function alive() {
		initSer();
	}

	public function initSer() {
		enableAutoReplication = true;
	}

	public function new( map : TmxMap, ?parentProc : Process ) {
		super( parentProc == null ? GameServer.inst : parentProc );
		initSer();

		tmxMap = map;

		for ( layer in tmxMap.layers ) {
			var name : String = 'null';
			switch( layer ) {
				case LObjectGroup( ol ):
					name = ol.name;
					for ( obj in ol.objects ) {
						if ( ol.name == 'obstacles' ) {
							switch( obj.objectType ) {
								case OTPolygon( points ):
									var pts = makePolyClockwise( points );
								case OTRectangle:
								default:
							}
						}
						if ( map.orientation == Isometric ) {
							// Если Entity никак не назван на карте - то ему присваивается имя его картинки без расширения
							if ( obj.name == "" ) {
								switch( obj.objectType ) {
									case OTTile( gid ):
										var objGid = Tools.getTileByGid( tmxMap, gid );
										if ( objGid != null
											&& eregFileName.match( objGid.image.source ) ) obj.name = eregFileName.matched( 1 );
									default:
								}
							}
							if ( ol.name == 'entities' ) {
								switch obj.objectType {
									case OTTile( gid ):
										Tools.propagateTilePropertiesToObject( obj, tmxMap, gid );
									default:
								}
								entitiesTmxObj.push( obj );
							}
						}
					}
				case LTileLayer( tl ):
					name = tl.name;
				default:
			}
			layersByName.set( name, layer );
		}
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		var entitiesId : Int = networkPropEntities.toInt();
		return
			switch( propId ) {
				case _ => entitiesId: true;
				default: false;
			}
	}

	@:rpc( immediate )
	public function addEntity( ent : Entity ) {
		entities.push( ent );
	}

	@:rpc( immediate )
	public function removeEntity( ent : Entity ) {
		entities.remove( ent );
	}

	// public inline function cartToIsoLocal( x : Float, y : Float ) : Vector {
	// 	return new Vector(
	// 		-( tmxMap.width - tmxMap.height ) / 2 * tmxMap.tileHeight + wid * .5 + cartToIso( x, y ).x,
	// 		hei - cartToIso( x, y ).y
	// 	);
	// }
	// destroys itself if has no player instances for 5 seconds
	function gc() {
		for ( e in entities ) {}
	}
}
