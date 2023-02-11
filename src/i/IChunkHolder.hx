package i;

import game.server.level.block.Block;
import game.server.level.Chunk;

interface IChunkHolder {
	function setChunk( x : Int, y : Int, chunk : Chunk ) : Void;
	function hasChunkAt( x : Int, y : Int ) : Bool;
	function removeChunk( x : Int, y : Int ) : Void;
	function setBlock( x : Int, y : Int, z : Int, block : Block ) : Void;
	function removeBlock( x : Int, y : Int, z : Int ) : Void;
}
