package en;

import dn.M;
import h3d.col.Point;
import util.Util;
import haxe.exceptions.NotImplementedException;
import h3d.Vector;
import format.tmx.Data;

using util.Extensions.ArrayExtensions;

class EntityTmxDataParser {

	public var collisions : Array<IsoPolyObjectConfig> = [];
	public var center : Vector;
	public var depth : EntityDepthConfig;
	public var tsTile : TmxTilesetTile;

	public static function fromTsTile( tsTile : TmxTilesetTile ) : EntityTmxDataParser {
		var ep = new EntityTmxDataParser();
		ep.tsTile = tsTile;

		var centerObj = tsTile.objectGroup.objects.filter( ( obj ) -> obj.name == "center" )[0];
		var depthObj = null;

		if ( centerObj != null ) {
			ep.center = new Vector( centerObj.x, centerObj.y );
		}

		for ( obj in tsTile.objectGroup.objects ) {
			if ( obj.name == "" ) {
				ep.collisions.push( IsoPolyObjectConfig.fromObject( obj, ep ) );
				continue;
			}

			var objConf = null;
			if ( StringTools.contains( obj.name, "collision" ) ) {
				objConf = IsoPolyObjectConfig.fromObject( obj, ep );
				ep.collisions.push( objConf );
			}

			if ( ep.depth == null && StringTools.contains( obj.name, "depth" ) ) {
				depthObj = obj;
				ep.depth = EntityDepthConfig.fromIsoConf(
					objConf != null ? objConf : IsoPolyObjectConfig.fromObject( obj, ep )
				);
			}
		}

		if ( ep.depth == null && centerObj != null ) {
			depthObj = centerObj;
			ep.depth = EntityDepthConfig.fromIsoConf(
				IsoPolyObjectConfig.fromObject( depthObj, ep )
			);
		}

		return ep;
	}

	public function new() {}
}

class IsoPolyObjectConfig {

	public var points : Array<Point>;
	public var centerOffset : Vector;
	public var properties : TmxProperties;

	public static function fromObject( obj : TmxObject, conf : EntityTmxDataParser ) : IsoPolyObjectConfig {

		var isoConf = new IsoPolyObjectConfig();
		isoConf.properties = obj.properties;

		function fromPoints( points : Array<TmxPoint> ) {
			var pts = Util.makePolyClockwise( points );
			isoConf.points = [];
			for ( pt in pts ) {
				var isoPt = Util.cartToIso( pt.x, -pt.y );
				isoPt = Util.isoToCart( isoPt.x, isoPt.y );
				isoConf.points.push( new Point( M.round( isoPt.x ), M.round( isoPt.y ) ) );
			}

			if ( conf.center == null ) {
				var cent = Util.getProjPolySize( isoConf.points, Vector );
				conf.center = new Vector( cent.x + obj.x, cent.y + obj.y );
			}

			isoConf.centerOffset = Util.cartToIso(
				conf.center.x - obj.x,
				-conf.center.y + obj.y
			);
			isoConf.centerOffset = Util.isoToCart(
				isoConf.centerOffset.x,
				isoConf.centerOffset.y
			);
			Util.rotatePoly( obj.rotation + 45, [isoConf.centerOffset] );
			Util.rotatePoly( obj.rotation - 135, isoConf.points );
		}

		switch obj.objectType {
			case OTPolygon( points ):
				fromPoints( points );
			case OTPoint:
				fromPoints( [{ x : obj.x, y : obj.y }] );
			default:
				throw new NotImplementedException();
		}

		return isoConf;
	}

	public inline function new() {}
}

/**
	iso sorting
**/
class EntityDepthConfig {

	public var leftPoint : Vector;
	public var rightPoint : Vector;

	public static function fromIsoConf( isoConf : IsoPolyObjectConfig ) {
		var conf = new EntityDepthConfig();

		var ptSorted = isoConf.points.copy();
		ptSorted.sort(
			( pt1, pt2 ) -> Util.isoToCart( pt1.x, pt1.y ).x < Util.isoToCart( pt2.x, pt2.y ).x ? -1 : 1
		);

		conf.leftPoint = new Vector(
			ptSorted.at( 0 ).x + isoConf.centerOffset.x,
			ptSorted.at( 0 ).y + isoConf.centerOffset.y
		);
		conf.rightPoint = new Vector(
			ptSorted.at( -1 ).x + isoConf.centerOffset.x,
			ptSorted.at( -1 ).y + isoConf.centerOffset.y
		);

		return conf;
	}

	public function new() {}
}
