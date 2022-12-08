package en;

import haxe.exceptions.NotImplementedException;
import h3d.Vector;
import format.tmx.Data;

using util.Extensions.ArrayExtensions;

class EntityTmxDataParser {

	public var collisions : Array<TmxObject> = [];
	public var center : Vector;
	public var depth : EntityDepthConfig;
	public var tsTile : TmxTilesetTile;

	public static function fromTsTile( tsTile : TmxTilesetTile ) : EntityTmxDataParser {
		var ep = new EntityTmxDataParser();
		ep.tsTile = tsTile;

		for ( obj in tsTile.objectGroup.objects ) {
			if ( ep.center == null && obj.name == "center" ) {
				ep.center = new Vector( obj.x, obj.y );
				continue;
			}
			if ( obj.name == "" ) {
				ep.collisions.push( obj );
				continue;
			}
			if ( StringTools.contains( obj.name, "collision" ) ) {
				ep.collisions.push( obj );
			}
			if ( ep.depth == null && StringTools.contains( obj.name, "depth" ) ) {
				ep.depth = EntityDepthConfig.fromTmxObject( obj );
			}
		}

		if ( ep.depth != null && ep.center != null ) {
			ep.depth.leftPoint.x -= ep.center.x;
			ep.depth.rightPoint.x -= ep.center.x;
			ep.depth.leftPoint.y -= ep.center.y;
			ep.depth.rightPoint.y -= ep.center.y;
		}

		return ep;
	}

	public function new() {}
}

/**
	iso sorting
**/
class EntityDepthConfig {

	public var leftPoint : Vector;
	public var rightPoint : Vector;

	public static function fromTmxObject( obj : TmxObject ) {
		var conf = new EntityDepthConfig();

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
