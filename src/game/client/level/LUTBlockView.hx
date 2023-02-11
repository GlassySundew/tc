package game.client.level;

import core.VO;
import h3d.scene.Object;
import game.client.level.batch.LUTBatcher.LUTBatchElement;
import game.server.level.block.TileBlock;
import format.tmx.Data.TmxTileset;

using format.tmx.Tools;
using util.Extensions.TilesetDataExtensions;

class LUTBlockView extends BlockView {

	var lutElem : LUTBatchElement;

	public function new( block : TileBlock, chunkView : ChunkView ) {
		super( chunkView );

		var tilesetLine = block.tileset.getTilesCountInLineOnTileset();

		var tsetTileX = ( ( block.tileGid - block.tileset.firstGID ) % tilesetLine );
		var tsetTileY = Math.floor( ( block.tileGid - block.tileset.firstGID ) / tilesetLine );

		var tilesetCache = GameClient.inst.levelView.tilesetCache.getLUT(
			Data.tileset.resolve( block.tileset.name )
		);

		if ( !tilesetCache.blockCache.exists( block.tileGid ) ) {
			var ts = Data.tileset.resolve( block.tileset.name );
			tilesetCache.blockCache[block.tileGid] = ts.bSearchModel( tsetTileX, tsetTileY );
		}

		var path = 'tiled/voxel/${block.tileset.name}/block_${tilesetCache.blockCache[block.tileGid]}.fbx';
		var depthOffset = ( block.z + block.depthOff ) * 0.2;

		lutElem = GameClient.inst.levelView.batcher.addMesh(
			path,
			tilesetCache.texture,
			tilesetCache.lutRows,
			block.x,
			block.y,
			block.z,
			tsetTileX * block.tileset.tileHeight,
			tsetTileY * block.tileset.tileHeight,
			depthOffset,
			LevelView.inst.root3d
		);
	}

	override function destroy() {
		super.destroy();
		lutElem.destroy();
	}
}
