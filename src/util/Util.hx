package util;

import format.tmx.Tools;
import format.tmx.TmxMap;
import dn.M;
import format.tmx.Data;
import format.tmx.Reader;
import h2d.Scene;
import h2d.Tile;
import h3d.Vector;
import hxd.Res;
import ui.NinesliceWindow.NinesliceConf;

using util.Extensions.TmxLayerExtender;
using util.Extensions.ArrayExtensions;
using util.Extensions.VectorExtensions;

typedef Point3 = {
	var x : Float;
	var y : Float;
	var z : Float;
}

@:publicFields
class Util {

	public inline static function makePolyClockwise<T : {
		x : Float,
		y : Float
	}, K>( points : Array<T> ) {

		var pts = points.copy();
		var sum = .0;
		for ( i => pt in pts ) {
			var nextIdx = ( i == pts.length - 1 ) ? 0 : i + 1;
			sum += ( pts[nextIdx].x - pt.x ) * ( pts[nextIdx].y + pt.y );
		}
		if ( sum < 0 ) pts.reverse();
		return pts;
	}

	public inline static function cartToIso( x : Float, y : Float ) : Vector
		return new Vector( ( x + y ), ( x - y ) );

	public inline static function isoToCart( x : Float, y : Float ) : Vector
		return new Vector( ( x - y ), ( x + y ) / 2 );

	public static var s3dWScaled( get, never ) : Int;

	inline static function get_s3dWScaled() return Std.int( Boot.inst.s2d.width / Const.SCALE );

	public static var s3dHScaled( get, never ) : Int;

	inline static function get_s3dHScaled() return Std.int( Boot.inst.s2d.height / Const.SCALE );

	public static var wScaled( get, never ) : Int;

	inline static function get_wScaled() return Std.int( Boot.inst.s2d.width / Const.UI_SCALE );

	public static var hScaled( get, never ) : Int;

	inline static function get_hScaled() return Std.int( Boot.inst.s2d.height / Const.UI_SCALE );

	inline static function getTileFromSeparatedTsx( tile : TmxTilesetTile ) : Tile {
		return Res.loader.load( haxe.io.Path.normalize( Const.LEVELS_PATH + tile.image.source ) ).toTile();
	}

	inline static function getTsx( tsx : Map<String, TmxTileset>, r : Reader ) : String -> TmxTileset {
		return ( name : String ) -> {
			var cached : TmxTileset = tsx.get( name );
			if ( cached != null ) return cached;
			cached = r.readTSX( Xml.parse( Res.loader.load( haxe.io.Path.normalize( Const.LEVELS_PATH + name ) ).entry.getText() ) );
			tsx.set( name, cached );
			return cached;
		}
	}

	/**
		@param lvlName must be unified
	**/
	inline static function resolveMap( lvlName : String ) {
		var tsx = new Map();
		var r = new Reader();
		r.resolveTSX = getTsx( tsx, r );
		var tmx = r.read( Xml.parse( Res.loader.load( Const.LEVELS_PATH + lvlName + ".tmx" ).entry.getText() ) );
		return tmx;
	}

	public inline static function roundTo( x : Float, y : Float ) : Float {
		return M.round( x / y ) * y;
	}

	inline static function emptyTiles( map : TmxMap ) return [for ( i in 0...( map.height * map.width ) ) new TmxTile( 0 )];

	static inline function rotatePoly<T : {
		x : Float,
		y : Float
	}>( angle, points : Array<T> ) {
		for ( pt in points ) {
			var old = new Vector( pt.x, pt.y );
			var angle = M.toRad( angle );

			pt.x = ( old.x ) * Math.cos( angle ) - ( old.y ) * Math.sin( angle );
			pt.y = ( old.x ) * Math.sin( angle ) + ( old.y ) * Math.cos( angle );
		}
	}

	/**
		https://stackoverflow.com/questions/15022630/how-to-calculate-the-angle-from-rotation-matrix
	**/
	public static inline function rotMatToEuler(
		r11 : Float,
		r21 : Float,
		r31 : Float,
		r32 : Float,
		r33 : Float
	) {
		var ax = Math.atan2( r32, r33 );
		var ay = Math.atan2(-r31, Math.sqrt( r32 * r32 + r33 * r33 ) );
		var az = Math.atan2( r21, r11 );

		return new Vector( ax, ay, az );
	}

	public static function getProjPolySize<T : {
		x : Float,
		y : Float
	}, K>(
		points : Array<T>,
		resultType : Class<K>
	) : K {
		var pts = makePolyClockwise( points );
		var verts : Array<Vector> = [];
		for ( i in pts ) verts.push( new Vector( ( i.x ), ( i.y ) ) );

		var yArr = verts.copy();
		yArr.sort( function ( a, b )
			return ( a.y < b.y ) ? -1 : ( ( a.y > b.y ) ? 1 : 0 )
		);
		var xArr = verts.copy();
		xArr.sort( function ( a, b )
			return ( a.x < b.x ) ? -1 : ( ( a.x > b.x ) ? 1 : 0 )
		);

		// xCent и yCent - половины ширины и высоты неповёрнутого полигона соответственно
		var xCent : Float = Std.int( ( xArr[xArr.length - 1].x + xArr[0].x ) * .5 );
		var yCent : Float = Std.int( ( yArr[yArr.length - 1].y + yArr[0].y ) * .5 );

		return Type.createInstance( resultType, [xCent, yCent] );
	}

	/**
		an unattached and unrendered scene, existing to 
		deceive heaps gc to not to destroy sprites 
		that are used by entity to render it onto a quad and etc
	**/
	public static var hollowScene : Scene;

	public static var uiMap : TmxMap;
	public static var uiConf : Map<String, TmxLayer>;

	public static var inventoryCoordRatio : Vector = new Vector( -1, -1 );

	public static function nineSliceFromConf(
		?conf : String = "window"
	) : NinesliceConf {
		var backgroundConf = uiConf.get( conf ).getObjectByName( "window" );
		var nineSlice = uiConf.get( conf ).getObjectByName( "9slice" );

		switch backgroundConf.objectType {
			case OTTile( gid ):
				var picName = Tools.getTileByGid( uiMap, gid ).image.source;
				if ( EregUtil.eregFileName.match( picName ) ) {
					return {
						atlasName : EregUtil.eregFileName.matched( 1 ),
						bl : Std.int( nineSlice.x ),
						bt : Std.int( nineSlice.y ),
						br : Std.int( nineSlice.width ),
						bb : Std.int( nineSlice.height )
					};
				} else
					throw "bad logic";
			default:
				throw "bad logic";
		}
	}

	public static function mapSize<K, V>( map : Map<K, V> ) {
		final addr = ( untyped $int( map ) : UInt );
		final size = hl.Bytes.fromAddress( addr ).offset( 44 ).getI32( 0 );

		return Std.int( size / 16 );
	}

	inline public static function unifyLevelName( level : String ) {
		if ( EregUtil.eregFileName.match( level ) )
			level = EregUtil.eregFileName.matched( 1 );
		return level;
	}

	public static inline function distToPoly<T : Point3>(
		from : Vector,
		to : Array<T>
	) : Float {

		var minDist = Math.POSITIVE_INFINITY;

		for ( i in 0...to.length ) {
			var p1 = to.at( i ).toVector();
			var p2 = to.at( i + 1 ).toVector();

			var r = p2.sub( p1 ).dot( from.sub( p1 ) );
			r /= Math.pow( p2.sub( p1 ).length(), 3 );

			var dist = minDist;

			if ( r < 0 )
				dist = from.sub( p1 ).length();
			else if ( r > 1 )
				dist = p2.sub( from ).length();
			else
				dist = Math.pow( Math.sqrt( from.sub( p1 ).length() ), 3 ) -
					Math.pow( r * p2.sub( p1 ).length(), 3 );

			minDist = Math.min( dist, minDist );
		}

		return minDist;
	}
}
