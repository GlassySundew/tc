package game.client.level;

import ch2.Tilemap;
import shader.VoxelDepther;
import shader.LUT;
import h3d.prim.Instanced;
import utils.tilesets.Tileset;
import utils.Assets;
import hxd.res.Model;
import h3d.scene.Mesh;
import hxd.Res;
import format.tmx.Data.TmxTileset;
import format.tmx.Tools;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxGroup;
import utils.TmxUtils;
import format.tmx.TmxMap;
import h3d.scene.Object;
import dn.Process;

using format.tmx.Tools;

class VoxelLevel extends Process {

	/** 
		a group name that when is found its containing will be converted into a 3d level
	**/
	private static final threeDLayerName = "3d";

	var threeDRoot : Object;
	var tmxMap : TmxMap;

	public function new( parent : Process ) {
		super( parent );
		threeDRoot = new Object( Boot.inst.s3d );
	}

	public function render( tmxMap : TmxMap ) {
		this.tmxMap = tmxMap;
		threeDRoot.removeChildren();
		TmxUtils.mapTmxMap(
			tmxMap,
			{
				tmxGroupLayerCb : ( tmxGroup : TmxGroup ) -> {
					return
						if ( tmxGroup.name == threeDLayerName ) {
							TmxUtils.layerRec( LGroup( tmxGroup ),
								{
									tmxTileLayerCb : ( tileLayer : TmxTileLayer ) -> {
										if ( tileLayer.visible )
											renderLayer( tileLayer );
										return true;
									}
								}
							);
							false;
						} else true;
				} }
		);
	}

	function createModel( nameAppend : String, tileset : TmxTileset ) : Mesh {
		var path = 'tiled/voxel/${tileset.name}/block_' + nameAppend + ".fbx";
		if ( !Res.loader.exists( path ) ) throw "model does not exists on path: " + path;
		return cast( Assets.modelCache.loadModel( Res.loader.load( path ).toModel() ), Mesh );
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

				var model = createModel( '${blockCache[tile.gid]}', tileset );
				Boot.inst.s3d.addChild( model );
				model.material.shadows = false;
				model.material.texture.filter = Nearest;
				var p = model.material.mainPass;
				p.addShader(
					new LUT(
						tsFigures.texture,
						tsFigures.lutRows,
						tsetTileX * tileset.tileHeight,
						tsetTileY * tileset.tileHeight
					)
				);

				p.addShader( new VoxelDepther( zheight + depthOff ) );

				model.x = ( tileidx % tmxMap.width ) * tmxMap.tileHeight + zheight * tmxMap.tileHeight;
				model.y = Math.floor( tileidx / tmxMap.width ) * tmxMap.tileHeight + zheight * tmxMap.tileHeight;
				model.z = zheight * tmxMap.tileHeight;
			}
		}
	}
}
