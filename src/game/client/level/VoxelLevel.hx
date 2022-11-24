package game.client.level;

import shader.LUT;
import hxd.Res;
import h3d.scene.Mesh;
import dn.Process;
import format.tmx.Data.TmxGroup;
import format.tmx.Data.TmxTileLayer;
import format.tmx.TmxMap;
import game.client.level.batch.LUTBatcher;
import h3d.scene.Object;
import i.IDestroyable;
import oimo.common.Vec3;
import utils.Assets;
import utils.oimo.OimoUtil;
import utils.tilesets.Tileset;
import utils.TmxUtils;

using format.tmx.Tools;

class VoxelLevel extends Process implements IDestroyable {

	/**
		a group name that when is found its containing will be converted into a 3d level
	**/
	private static final threeDLayerName = "3d";

	var threeDRoot : Object;
	var tmxMap : TmxMap;
	var batcher : LUTBatcher;

	public function new( parent : Process ) {
		super( parent );
		threeDRoot = new Object( Boot.inst.s3d );
		batcher = new LUTBatcher();
	}

	public function toggleVisible() {
		threeDRoot.visible = !threeDRoot.visible;
	}

	public function render( tmxMap : TmxMap ) {
		this.tmxMap = tmxMap;

		threeDRoot.removeChildren();
		TmxUtils.mapTmxMap(
			tmxMap,
			{
				tmxTileLayerCb : ( tileLayer : TmxTileLayer ) -> {
					if ( tileLayer.visible )
						renderLayer( tileLayer );
					return true;
				}
			}
		);

		return this;
	}

	override function onDispose() {
		super.onDispose();

		threeDRoot.removeChildren();
	}

	override function update() {
		super.update();
		inline batcher.emitAll();
	}

	var blockCache : Map<Int, Int> = [];

	function renderLayer( tileLayer : TmxTileLayer ) {
		var zheight = tileLayer.properties.existsType( "zheight", PTFloat ) ? tileLayer.properties.getFloat( "zheight" ) : 0.;
		var depthOff = tileLayer.properties.existsType( "depthOff", PTInt ) ? tileLayer.properties.getInt( "depthOff" ) : 0;

		for ( tileidx => tile in tileLayer.data.tiles ) {
			if ( tile.gid != 0 ) {

				var tileset = Tools.getTilesetByGid( tmxMap, tile.gid );
				var tilesetLine = tileset.getTilesCountInLineOnTileset();
				var tsFigures : Tileset = Reflect.field( Assets, tileset.name );
				var tsetTileX = ( ( tile.gid - tileset.firstGID ) % tilesetLine );
				var tsetTileY = Math.floor( ( tile.gid - tileset.firstGID ) / tilesetLine );

				if ( !blockCache.exists( tile.gid ) )
					blockCache[tile.gid] = tsFigures.bSearchModel( tsetTileX, tsetTileY, tsetTileX );

				var tileX = ( tileidx % tmxMap.width );
				var tileY = Math.floor( tileidx / tmxMap.width );

				var x = tileX * tmxMap.tileHeight + zheight * tmxMap.tileHeight;
				var y = tileY * tmxMap.tileHeight + zheight * tmxMap.tileHeight;
				var z = zheight * tmxMap.tileHeight;

				var path = 'tiled/voxel/${tileset.name}/block_${blockCache[tile.gid]}.fbx';
				var verticalDepth = ( zheight + depthOff ) * 0.02;
				var horizontalDepth = ( tileX - tileY ) * 0.000001;

				/*
					inline function loadMesh( path : String ) : Mesh {
						if ( !Res.loader.exists( path ) ) throw "model does not exists on path: " + path;
						return cast( Assets.modelCache.loadModel( Res.loader.load( path ).toModel() ), Mesh );
					}

					var mesh = loadMesh( path );
					threeDRoot.addChild( mesh );
					var lut = new LUT( tsFigures.texture, tsFigures.lutRows, tsetTileX * tileset.tileHeight, tsetTileY * tileset.tileHeight );
					mesh.material.mainPass.addShader( lut );
					var depth = new shader.DepthOffset(verticalDepth);
					mesh.material.mainPass.addShader( depth );
					mesh.material.texture.filter = Nearest;
					mesh.material.shadows = false;

					mesh.x = x;
					mesh.y = y;
					mesh.z = z;
				 */

				batcher.addMesh(
					path,
					tsFigures.texture,
					tsFigures.lutRows,
					x,
					y,
					z,
					tsetTileX * tileset.tileHeight,
					tsetTileY * tileset.tileHeight,
					verticalDepth,
					threeDRoot
				);

				OimoUtil.addBox(
					Level.inst.world,
					new Vec3( x + ( tmxMap.tileHeight >> 1 ), y + ( tmxMap.tileHeight >> 1 ), z + ( tmxMap.tileHeight + 1 ) / 2 ),
					new Vec3( tmxMap.tileHeight >> 1, tmxMap.tileHeight >> 1, ( tmxMap.tileHeight + 1 ) / 2 ),
					true
				);
			}
		}
	}
}
