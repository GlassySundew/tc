package game.server.level;

import game.server.level.block.TileBlock;
import game.server.level.block.Block;
import format.tmx.Tools;

using format.tmx.Tools;

class LevelController {

	var level : ServerLevel;

	public function new( level : ServerLevel ) {
		this.level = level;
	}

	public inline function placeBlockTmx(
		idx : Int,
		z : Int,
		tile : format.tmx.Data.TmxTile,
		tmxMap : format.tmx.TmxMap
	) {
		var tileX = ( idx % tmxMap.width );
		var tileY = Math.floor( idx / tmxMap.width );

		var block = new TileBlock();
		block.tileset = Tools.getTilesetByGid( tmxMap, tile.gid );
		block.tileGid = tile.gid;
		
		level.chunks.placeBlock( tileX, tileY, z, block );
	}
}
