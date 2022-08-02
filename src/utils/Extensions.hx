package utils;

import net.Message;
import hxd.net.Socket;
import hxd.net.SocketHost;
import format.tmx.Data.TmxObject;
import format.tmx.Data.TmxLayer;
import format.tmx.TmxMap;
import seedyrng.Random;
import hxbit.NetworkHost.NetworkClient;
import h2d.Flow;

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
