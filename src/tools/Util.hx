package tools;

import format.tmx.*;
import format.tmx.Data;
import format.tmx.Reader;
import h2d.Flow;
import h2d.Scene;
import h2d.Tile;
import h3d.Vector;
import hxbit.NetworkHost.NetworkClient;
import hxd.Res;
import hxd.net.Socket;
import hxd.net.SocketHost;
import seedyrng.Random;
import ui.NinesliceWindow.NinesliceConf;

@:publicFields
@:expose
class Util {

	/**Regex to get class name provided by CompileTime libs, i.e. en.$Entity -> Entity **/
	static var eregCompTimeClass = ~/\$([a-zA-Z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** regex to match automapping random rules **/
	static var eregAutoMapRandomLayer = ~/(?:output|input)([0-9]+)_([a-z]+)$/gi;

	/** regex to match automapping inputnot rules **/
	static var eregAutoMapInputNotLayer = ~/(?:input)not_([a-z]+)$/gi;

	/** Regex to get '$this' class name i.e. en.Entity -> Entity **/
	static var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Регулярка чтобы взять из абсолютного пути название файла без расширения .png **/
	static var eregFileName = ~/\/([a-z_0-9]+)\./;

	// @:deprecated
	// inline static function loadTileFromCdb( cdbTile : TilePos ) : Tile {
	// 	return Res.loader.loadParentalFix(cdbTile.file).toTile().sub(cdbTile.x * cdbTile.size, cdbTile.y * cdbTile.size, cdbTile.size, cdbTile.size);
	// }

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

	inline static function getTileSource( gid : Int, tileset : TmxTileset ) : TmxTilesetTile {
		var fixedGId = gid - tileset.firstGID;
		// фикс на непоследовательные id тайлов
		for ( i in 0...tileset.tiles.length ) if ( tileset.tiles[i].id == fixedGId && fixedGId > i ) while( fixedGId > i )
			fixedGId--;
		return ( tileset.tiles[fixedGId] );
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

	inline static function resolveMap( lvlName : String ) {
		var tsx = new Map();
		var r = new Reader();
		r.resolveTSX = getTsx( tsx, r );
		var tmx = r.read( Xml.parse( Res.loader.load( Const.LEVELS_PATH + lvlName + ( StringTools.endsWith( lvlName, ".tmx" ) ? "" : ".tmx" ) ).entry.getText() ) );
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

	static var entParent : Scene;

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
}

class ReverseIterator {

	var end : Int;
	var i : Int;

	public inline function new( start : Int, end : Int ) {
		this.i = start;
		this.end = end;
	}

	public inline function hasNext() return i >= end;

	public inline function next() return i--;
}

class ReverseArrayKeyValueIterator<T> {

	final arr : Array<T>;
	var i : Int;

	public inline function new( arr : Array<T> ) {
		this.arr = arr;
		this.i = this.arr.length - 1;
	}

	public inline function hasNext() return i > -1;

	public inline function next() {
		return { value : arr[i], key : i-- };
	}

	public static inline function reversedKeyValues<T>( arr : Array<T> ) {
		return new ReverseArrayKeyValueIterator( arr );
	}
}

class MathUtil {

	/**
		Uses Math.round to fix a floating point number to a set precision.
	**/
	public static function round( number : Float, ?precision = 2 ) : Float {
		number *= Math.pow( 10, precision );
		return Math.round( number ) / Math.pow( 10, precision );
	}
}

class SeedyRandomExtender {

	public static function seededString( r : Random, length : Int, ?charactersToUse = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" ) {
		var str = "";
		for ( i in 0...length ) {
			str += charactersToUse.charAt( r.randomInt( 0, charactersToUse.length - 1 ) );
		}
		return str;
	}
}

class TmxMapExtender {

	public static function getLayersByName( map : TmxMap, name : String ) : Array<TmxLayer> {
		return map.layers.filter( layer -> switch layer {
			case LTileLayer( layer ):
				layer.name == name;
			case LObjectGroup( group ):
				group.name == name;
			case LImageLayer( layer ):
				layer.name == name;
			case LGroup( group ):
				group.name == name;
		} );
	}

	public static function mapLayersByName( tmxMap : TmxMap ) : Map<String, TmxLayer> {
		var map : Map<String, TmxLayer> = [];
		for ( i in tmxMap.layers ) {
			var name : String = 'null';
			switch( i ) {
				case LObjectGroup( group ):
					name = group.name;
				case LTileLayer( tl ):
					name = tl.name;
				default:
			}
			map.set( name, i );
		}
		return map;
	}
}

class TmxLayerExtender {

	public static function getObjectByName( tmxLayer : TmxLayer, name : String ) : TmxObject {
		switch( tmxLayer ) {
			case LObjectGroup( group ):
				for ( i in group.objects ) {
					if ( i.name == name ) return i;
				}
			default:
		}
		return null;
	}

	/** Localises all objects of this layer to be local to certain object of this layer **/
	public static function localBy( tmxLayer : TmxLayer, target : TmxObject ) {
		switch( tmxLayer ) {
			case LObjectGroup( group ):
				// Offsetting every single object in the layer
				var offsetX = -target.width / 2 + target.x + 1;
				var offsetY = -target.height + target.y + 1;
				for ( i in group.objects ) {
					i.x -= offsetX;
					i.y -= offsetY;
					switch( i.objectType ) {
						case OTTile( gid ):
							i.x -= i.width / 2 - 1;
							i.y -= i.height - 1;
						default:
					}
				}
			default:
		}
		return null;
	}
}

class SocketHostExtender {

	static public function waitFixed(
		sHost : SocketHost,
		host : String,
		port : Int,
		?onConnected : NetworkClient -> Void,
		?onError : SocketClient -> String -> Void
	) @:privateAccess {

		sHost.close();
		sHost.isAuth = false;
		sHost.socket = new Socket();
		sHost.self = new SocketClient( sHost, null );
		sHost.socket.bind( host, port, function ( s ) {
			var c = new SocketClient( sHost, s );
			sHost.pendingClients.push( c );
			s.onError = function ( e ) {
				if ( onError != null ) onError( c, e );
				c.stop();
			}
			if ( onConnected != null ) onConnected( c );
		} );
		sHost.isAuth = true;
	}

	public static function sendTypedMessage( sHost : hxd.net.SocketHost, msg : Message, ?to : NetworkClient ) sHost.sendMessage( msg, to );

	public static dynamic function onTypedMessage( sHost : hxd.net.SocketHost, onMessage : NetworkClient -> Message -> Void ) {
		sHost.onMessage = onMessage;
	}
}

class FlowExtender {

	public static function center( flow : Flow ) {
		flow.paddingLeft = -flow.innerWidth >> 1;
		flow.paddingTop = -flow.innerHeight >> 1;
	}
}
