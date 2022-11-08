package game.client.level;

import cherry.soup.EventSignal.EventSignal0;
import dn.M;
import dn.Process;
import en.items.Blueprint;
import en.objs.IsoTileSpr;
import en.player.Player;
import format.tmx.*;
import format.tmx.Data;
import h2d.Bitmap;
import h2d.Tile;
import h3d.Vector;
import h3d.col.Bounds;
import h3d.col.Point;
import h3d.mat.Texture;
import h3d.scene.Interactive;
import h3d.scene.Object;
import hxd.IndexBuffer;
import hxd.Res;
import i.IDestroyable;
import oimo.common.Vec3;
import oimo.dynamics.World;
import tiled.TileLayerRenderer;
import ui.s3d.EventInteractive;
import utils.Const;
import utils.Util;
import utils.oimo.OimoDebugRenderer;

using utils.TmxUtils;

/**
	client-side level rendering
	Level parses tmx entities maps, renders tie layers into mesh
**/
class Level extends dn.Process {

    public static var inst : Level;

    public inline function getLayerByName( id : String ) return layersByName.get( id );

    public var wid( get, never ) : Int;

    public var hei( get, never ) : Int;

    inline function get_wid( ) return Std.int( ( Math.min( tmxMap.height, tmxMap.width ) + Math.abs( -tmxMap.width + tmxMap.height ) / 2 ) * tmxMap.tileWidth );

    inline function get_hei( ) return Std.int( ( Math.min( tmxMap.height, tmxMap.width ) + Math.abs( -tmxMap.width + tmxMap.height ) / 2 ) * tmxMap.tileHeight );

    public var sqlId : Null<Int>;
    public var lvlName : String;

    public var entities : Array<TmxObject> = [];
    public var ground : Texture;
    public var obj : IsoTileSpr;

    public var tmxMap : TmxMap;

    var layersByName : Map<String, TmxLayer> = new Map();
    var levelRenderer : IDestroyable;

    /**
		3d x coord of cursor
	**/
    public var cursX : Float;

    /**
		3d z coord of cursor
	**/
    public var cursY : Float;

    public var cursorInteract : Interactive;
    public var world : World;
    public var oimoDebug : OimoDebugRenderer;
    public var onRenderedSignal = new EventSignal0();

    public function new( map : TmxMap ) {
        super( GameClient.inst );
        world = new World( new Vec3( 0, 0, -9.80665 ) ); //
        inst = this;
        tmxMap = map;

        Boot.inst.engine.backgroundColor = tmxMap.backgroundColor;
        Boot.inst.s3d.camera.setFovX( 70, Boot.inst.s3d.camera.screenRatio );

        for ( layer in map.layers ) {
            var name : String = 'null';
            switch( layer ) {
                case LObjectGroup( ol ):
                    name = ol.name;
                    for ( obj in ol.objects ) {
                        if ( ol.name == 'obstacles' ) {
                            switch( obj.objectType ) {
                                case OTPolygon( points ):
                                    var pts = Util.makePolyClockwise( points );
                                case OTRectangle:
                                default:
                            }
                        }
                    }
                default:
            }
        }

        render( );
    }

    // function get_lid() {
    // 	var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
    // 	if ( !reg.match(Game.inst.lvlName) ) return -1; else
    // 		return Std.parseInt(reg.matched(1));
    // }

    override function onDispose( ) {
        super.onDispose( );

        obj.remove( );
        if ( obj != null ) obj.primitive.dispose( );
        cursorInteract.remove( );
        if ( ground != null ) ground.dispose( );

        if ( levelRenderer != null ) levelRenderer.destroy( );

        tmxMap = null;
        obj = null;
        entities = null;
        layersByName = null;
    }

    public function getEntities( id : String ) {
        var a = [];
        for ( e in entities ) if ( e.name == id ) a.push( e );
        return a;
    }

    function render( ) {
        if ( tmxMap.isMap3d( ) ) {
            render3d( );
        } else
            renderPlane( );
        onRenderedSignal.dispatch( );
    }

    /**
		CONGRUENT tileset
	**/
    function render3d( ) {
        levelRenderer = new VoxelLevel( this ).render( tmxMap );
        
        #if colliders_debug
        oimoDebug = new OimoDebugRenderer( this ).initWorld( world );
        #end
    }

    /**
		render level to a square 2d plane, deprecated
	**/
    function renderPlane( ) {
        var layerRenderer : LayerRender;

        ground = new h3d.mat.Texture( wid, hei, [Target] );
        ground.filter = Nearest;

        obj = new IsoTileSpr( Tile.fromTexture( ground ), false );
        obj.alwaysSync = false;
        obj.rotate( 0, 0, M.toRad( 90 ) );

        @:privateAccess obj.z += hei;
        obj.material.shadows = false;
        obj.material.mainPass.enableLights = false;
        obj.material.mainPass.depth( false, LessEqual );
        obj.material.mainPass.setBlendMode( Alpha );

        TmxUtils.mapTmxMap(
            tmxMap,
            cast {
                tmxTileLayerCb : ( layer ) -> {
                    if ( layer.visible #if !display_proto && layer.name != "proto" #end ) {
                        layerRenderer = new LayerRender( tmxMap, wid, hei, layer );
                        layerRenderer.render.g.drawTo( ground );
                    }
                    return true;
                }
            }
        );

        // чтобы получать 3d координаты курсора
        {
            var bounds = new Bounds();
            bounds.addPoint( new Point( 0, 0, 0 ) );
            bounds.addPoint( new Point( wid, 0, hei ) );

            cursorInteract = new h3d.scene.Interactive( bounds, Boot.inst.s3d );
            cursorInteract.propagateEvents = true;
            cursorInteract.cursor = Default;
            cursorInteract.onMove = function( e : hxd.Event ) {
                cursX = e.relX;
                cursY = e.relZ;
            }
            cursorInteract.priority = -10;
        }
    }

    override function preUpdate( ) {
        super.preUpdate( );
    }

    override function update( ) {
        super.update( );
    }

    override function postUpdate( ) {
        super.postUpdate( );
    }

    public inline function cartToIsoLocal( x : Float, y : Float ) : Vector {
        return new Vector(
        -( tmxMap.width - tmxMap.height ) / 2 * tmxMap.tileHeight + wid * .5 + Util.cartToIso( x, y ).x,
        hei - Util.cartToIso( x, y ).y
        );
    }
}

class LayerRender extends h2d.Object {

    public var render : InternalRender;

    public function new( map : TmxMap, wid : Int, hei : Int, layer : TmxTileLayer ) {
        super( );
        render = new InternalRender( map, layer );
        render.g = new h2d.Graphics();
        render.g.blendMode = Alpha;
        render.tex = new Texture( wid, hei, [Target] );

        render.render( );
    }
}

private class InternalRender extends TileLayerRenderer {

    public var g : h2d.Graphics;

    public var tex : Texture;

    private var uv : Point = new Point();

    override function renderOrthoTile( x : Float, y : Float, tile : TmxTile, tileset : TmxTileset ) : Void {
        if ( tileset == null ) return;

        x -= ( Std.int( ( ( map.width - map.height ) / 2 ) * map.tileWidth ) );

        if ( tileset.image == null ) {
            renderOrthoTileFromImageColl( x, y, tile, tileset, map );
            return;
        }

        if ( tileset.tileOffset != null ) {
            x += tileset.tileOffset.x;
            y += tileset.tileOffset.y;
        }

        var scaleX = tile.flippedHorizontally ? -1 : 1;
        var scaleY = tile.flippedVertically ? -1 : 1;
        Tools.getTileUVByLidUnsafe( tileset, tile.gid - tileset.firstGID, uv );
        var h2dTile = Res.loader.load( Const.LEVELS_PATH + tileset.image.source ).toTile( );

        g.beginTileFill(
            x
            - uv.x
            + ( scaleX == 1 ? 0 : map.tileWidth )
            + layer.offsetX,
            y
            - uv.y * scaleY
            + map.tileHeight
            - tileset.tileHeight / ( scaleY == 1 ? 1 : 1 )
            + layer.offsetY, scaleX, scaleY, h2dTile
        );
        g.drawRect( x, y + map.tileHeight - tileset.tileHeight, tileset.tileWidth, tileset.tileHeight );
        g.endFill( );

        h2dTile.dispose( );
        h2dTile = null;
    }

    function renderOrthoTileFromImageColl( x : Float, y : Float, tile : TmxTile, tileset : TmxTileset, tmxMap : TmxMap ) : Void {
        var sourceTile = Tools.getTileByGid( tmxMap, tile.gid );
        var h2dTile = Util.getTileFromSeparatedTsx( sourceTile );

        var bmp = new Bitmap( h2dTile );
        if ( tile.flippedDiagonally ) bmp.rotate( M.toRad( tile.flippedVertically ? -90 : 90 ) );

        var scaleX = ( tile.flippedHorizontally && !tile.flippedDiagonally ) ? -1 : 1;
        var scaleY = ( tile.flippedVertically && !tile.flippedDiagonally ) ? -1 : 1;

        bmp.scaleX = scaleX;
        bmp.scaleY = scaleY;

        bmp.x = x + ( scaleX > 0 ? 0 : h2dTile.width ) + ( tile.flippedDiagonally ? ( tile.flippedHorizontally ? h2dTile.height : 0 ) : 0 );
        bmp.y = y
                - h2dTile.height
                + map.tileHeight
                + ( scaleY > 0 ? 0 : h2dTile.height )
                - layer.offsetX
                + layer.offsetY
                + ( tile.flippedDiagonally ? ( tile.flippedVertically ? h2dTile.height : -h2dTile.width + h2dTile.height ) : 0 );

        // Creating isometric(rombic) h3d.scene.Interactive on top of separated
        // tiles that contain * at the end of their file name as a slots for
        // structures; can be visible only when choosing place for structure to build

        // Это должно быть visible только тогда, когда у игрока в holdItem есть blueprint
        if (
        Util.eregFileName.match( sourceTile.image.source )
        && StringTools.endsWith( Util.eregFileName.matched( 1 ), "floor" ) )
            GameClient.inst.structTiles.push(
                new StructTile( bmp.x + Level.inst.tmxMap.tileWidth / 2,
                Level.inst.hei - bmp.y - Level.inst.tmxMap.tileHeight / 2 + 2, Boot.inst.s3d )
            );

        bmp.drawTo( tex );
        bmp.tile.dispose( );
        bmp.remove( );
        bmp = null;

        g.clear( );
        g.drawTile( 0, 0, Tile.fromTexture( tex ) );
    }

    override function renderIsoTiles( ox : Float, y : Float, tiles : Array<TmxTile>, width : Int, height : Int ) {
        var i : Int = 0;
        var ix : Int = 0;
        var iy : Int = 0;
        var x : Float = ox;
        var tset : TmxTileset;
        var tile : TmxTile;
        var hw : Float = map.tileWidth / 2;
        var hh : Float = map.tileHeight / 2;

        while ( i < tiles.length ) {
            tile = tiles[i];
            renderIsoTile( x + ( ( ix - iy ) * hw ) + Std.int( map.tileWidth * map.width / 2 - hw ), y + ( ix + iy ) * hh, tile, Tools.getTilesetByGid( map, tile.gid ) );
            i++;
            if ( ++ix == width ) {
                ix = 0;
                iy++;
                // x = ox;
                // y += hh;
            } else {
                // x += hw;
            }
        }
    }
}

class StructTile extends Object {

    public var taken : Bool = false;
    public var tile : EventInteractive;

    // Шаблон, из которого берётся коллайдер для tile
    public static var polyPrim : h3d.prim.Polygon = null;

    // Ortho size of tile
    public static var tileW : Int = 44;
    public static var tileH : Int = 20;

    public function new( x : Float, y : Float, ?parent : Object ) {
        super( parent );

        if ( polyPrim == null ) initPolygon( );
        tile = new EventInteractive( polyPrim.getCollider( ), this );
        tile.rotate( -0.01, 0, hxd.Math.degToRad( 180 ) );

        tile.propagateEvents = true;
        this.x = x;
        this.z = y;
        this.y = 0;

        tile.onMoveEvent.add( ( event ) -> {
            if ( Player.inst != null && Player.inst.holdItem != null && Std.isOfType( Player.inst.holdItem, Blueprint ) ) {
                cast( Player.inst.holdItem, Blueprint ).onStructTileMove.dispatch( this );
            }
        } );

        tile.onClickEvent.add( event -> {
            if ( Player.inst != null && Player.inst.holdItem != null && Std.isOfType( Player.inst.holdItem, Blueprint ) ) {
                cast( Player.inst.holdItem, Blueprint ).onStructurePlace.dispatch( this );
            }
        } );
        #if debug
        // var prim = new h3d.prim.Cube();

        // // translate it so its center will be at the center of the cube
        // prim.translate(-0.5, -0.5, -0.5);

        // // unindex the faces to create hard edges normals
        // prim.unindex();

        // // add face normals
        // prim.addNormals();

        // // add texture coordinates
        // prim.addUVs();
        // var obj2 = new Mesh(prim, this);
        // obj2.scale(10);
        // // set the second cube color
        // obj2.material.color.setColor(0xFFB280);
        // obj2.material.shadows = false;
        #end
    }

    public function initPolygon( ) {
        var pts : Array<Point> = [];
        pts.push( new Point( tileW / 2, 0, 0 ) );
        pts.push( new Point( 0, 0, -tileH / 2 ) );
        pts.push( new Point( tileW / 2, 0, -tileH ) );
        pts.push( new Point( tileW, 0, -tileH / 2 ) );

        var idx = new IndexBuffer();
        idx.push( 0 );
        idx.push( 1 );
        idx.push( 2 );

        idx.push( 0 );
        idx.push( 2 );
        idx.push( 3 );
        polyPrim = new h3d.prim.Polygon( pts, idx );
        polyPrim.translate( -tileW / 2, 0, tileH / 2 );
    }
}
