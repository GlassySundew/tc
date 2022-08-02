package utils;

import format.tmx.*;
import format.tmx.Data;
import format.tmx.Reader;
import h2d.Scene;
import h2d.Tile;
import h3d.Vector;
import hxd.Res;
import ui.NinesliceWindow.NinesliceConf;

@:publicFields
@:expose
class Util {

	/** Regex to get class name provided by CompileTime libs, i.e. en.$Entity -> Entity **/
	static var eregCompTimeClass = ~/\$([a-zA-Z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** regex to match automapping random rules **/
	static var eregAutoMapRandomLayer = ~/(?:output|input)([0-9]+)_([a-z]+)$/gi;

	/** regex to match automapping inputnot rules **/
	static var eregAutoMapInputNotLayer = ~/(?:input)not_([a-z]+)$/gi;

	/** Regex to get '$this' class name i.e. en.Entity -> Entity **/
	static var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Регулярка чтобы взять из абсолютного пути название файла без расширения .png **/
	static var eregFileName = ~/\/*([a-z_0-9]+)\./;

	inline static function makePolyClockwise( points : Array<TmxPoint> ) {
		var pts = points.copy();
		var sum = .0;
		for ( i => pt in pts ) {
			var nextIdx = ( i == pts.length - 1 ) ? 0 : i + 1;
			sum += ( pts[nextIdx].x - pt.x ) * ( pts[nextIdx].y + pt.y );
		}
		sum < 0 ? pts.reverse() : {};
		return pts;
	}

	inline static function cartToIso( x : Float, y : Float ) : Vector return new Vector( ( x - y ), ( x + y ) / 2 );

	inline static function screenToIsoX( globalX : Float, globalY : Float ) {
		return globalX + globalY;
	}

	inline static function screenToIsoY( globalX : Float, globalY : Float ) {
		return globalY - globalX / 2;
	}

	inline static function screenToIso( globalX : Float, globalY : Float ) {
		return new Vector( screenToIsoX( globalX, globalY ), screenToIsoY( globalX, globalY ) );
	}

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

	inline static function emptyTiles( map : TmxMap ) return [for ( i in 0...( map.height * map.width ) ) new TmxTile( 0 )];

	static inline function rotatePoly( obj : TmxObject, points : Array<TmxPoint> ) {
		for ( pt in points ) {
			var old = new Vector( pt.x, pt.y );
			var angle = M.toRad( obj.rotation );

			pt.x = ( old.x ) * Math.cos( angle ) - ( old.y ) * Math.sin( angle );
			pt.y = ( old.x ) * Math.sin( angle ) + ( old.y ) * Math.cos( angle );
		}
	}

	static function getProjectedDifferPolygonRect( ?obj : TmxObject, points : Array<TmxPoint> ) : differ.math.Vector {
		var pts = makePolyClockwise( points );
		var verts : Array<Vector> = [];
		for ( i in pts ) verts.push( new Vector( ( i.x ), ( i.y ) ) );

		var yArr = verts.copy();
		yArr.sort( function ( a, b ) return ( a.y < b.y ) ? -1 : ( ( a.y > b.y ) ? 1 : 0 ) );
		var xArr = verts.copy();
		xArr.sort( function ( a, b ) return ( a.x < b.x ) ? -1 : ( ( a.x > b.x ) ? 1 : 0 ) );

		// xCent и yCent - половины ширины и высоты неповёрнутого полигона соответственно
		var xCent : Float = Std.int( ( xArr[xArr.length - 1].x + xArr[0].x ) * .5 );
		var yCent : Float = Std.int( ( yArr[yArr.length - 1].y + yArr[0].y ) * .5 );

		return new differ.math.Vector( xCent, yCent );
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

	public static function nineSliceFromConf( ?conf : String = "window" ) : NinesliceConf {
		var backgroundConf = uiConf.get( conf ).getObjectByName( "window" );
		var nineSlice = uiConf.get( conf ).getObjectByName( "9slice" );

		switch backgroundConf.objectType {
			case OTTile( gid ):
				var picName = Tools.getTileByGid( uiMap, gid ).image.source;
				if ( eregFileName.match( picName ) ) {
					return {
						atlasName : eregFileName.matched( 1 ),
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

	@:generic
	public static function mapSize<K, V>( map : Map<K, V> ) {
		final addr = ( untyped $int( map ) : UInt );
		final size = hl.Bytes.fromAddress( addr ).offset( 44 ).getI32( 0 );

		return Std.int( size / 16 );
	}

	inline public static function unifyLevelName( level : String ) {
		if ( eregFileName.match( level ) ) level = eregFileName.matched( 1 );
		return level;
	}
}
