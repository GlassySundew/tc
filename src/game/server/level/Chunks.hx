package game.server.level;

import dn.M;
import game.server.level.block.Block;
import net.NetNode;

class Chunks {

	var chunks : Array<Array<Chunk>> = [];
	var level : ServerLevel;

	public function new( level ) {
		this.level = level;
	}

	public inline function get( x : Int, y : Int ) : Chunk {
		if ( chunks[x] == null ) chunks[x] = [];
		if ( chunks[x][y] == null ) chunks[x][y] = new Chunk();
		return chunks[x][y];
	}

	public inline function placeBlock( x : Int, y : Int, z : Int, block : Block ) {
		var chunkX = M.floor( x / level.cdb.chunkSize );
		var chunkY = M.floor( y / level.cdb.chunkSize );

		get( chunkX, chunkY ).setBlock( x, y, z, block );
	}
}
