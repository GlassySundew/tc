package en;

import haxe.exceptions.NotImplementedException;
import h3d.Vector;
import format.tmx.Data;

using util.Extensions.ArrayExtensions;

class EntityTmxDataParser {

	public var collisions : Array<TmxObject> = [];
	public var depth : TmxObject;

	public static function fromTsTile( tsTile : TmxTilesetTile ) : EntityTmxDataParser {
		var ep = new EntityTmxDataParser();

		var depthObj : TmxObject = null;
		
		for ( obj in tsTile.objectGroup.objects ) {
			if ( obj.name == "" ) {
				ep.collisions.push( obj );
				continue;
			}
			if ( StringTools.contains( obj.name, "collision" ) ) {
				ep.collisions.push( obj );
			}
			if ( StringTools.contains( obj.name, "depth" ) ) {
				if ( ep.depth != null ) trace( "WARNING: DOUBLE DEPTH DEFINITION" );
				ep.depth = obj;
			}
		}

		if ( ep.depth != null )
			EntityDepthOffsetConfig.fromTmxObject( ep.depth );

		return ep;
	}

	public function new() {}
}

class EntityDepthOffsetConfig {

	public var leftPoint : Vector;
	public var rightPoint : Vector;

	public static function fromTmxObject( obj : TmxObject ) {
		var conf = new EntityDepthOffsetConfig();

		var points = switch obj.objectType {
			case OTPolygon( points ):
				var ptSorted = points.copy();
				ptSorted.sort( ( pt1, pt2 ) -> pt1.x < pt2.x ? -1 : 1 );
				ptSorted;
			default:
				throw new NotImplementedException();
		}

		conf.leftPoint = new Vector( points.at( 0 ).x, points.at( 0 ).y );
		conf.rightPoint = new Vector( points.at( -1 ).x, points.at( -1 ).y );

		return conf;
	}

	public function new() {}
}
