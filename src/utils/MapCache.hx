package utils;

import sys.thread.Lock;
import hx.concurrent.executor.Executor.TaskFuture;
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;
import format.tmx.TmxMap;
import haxe.ds.Map;
import haxe.Constraints.IMap;

class MapCache extends StringMap<TmxMap> {

    static var _inst : MapCache;
    public static var inst( get, default ) : MapCache;

    var lock : Lock;

    public var locked : Bool = false;

    static function get_inst( ) : MapCache {
        if ( _inst == null ) new MapCache();
        return _inst;
    }

    /** multithreading modification of get method **/
    public function getLocked( key : String ) {
        if ( locked ) lock.wait( );

        locked = true;
        var mapFound = super.get( key );

        if ( mapFound == null ) {
            var map = Util.resolveMap( key );
            super.set( key, map );
            locked = false;
            lock.release( );
            return map;
        } else {
            locked = false;
            lock.release( );
            return mapFound;
        }
    }

    override function get( key : String ) : Null<TmxMap> {
        var mapFound = super.get( key );
        if ( mapFound == null ) {
            var map = Util.resolveMap( key );
            this.set( key, map );
            return map;
        } else
            return mapFound;
    }

    public function new( ) {
        super( );
        _inst = this;
        lock = new Lock();
    }
}
