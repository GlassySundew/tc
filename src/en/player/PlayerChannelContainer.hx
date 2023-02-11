package en.player;

import game.server.level.block.Block;
import game.server.level.Chunk;
import net.NSIntMap;
import i.IChunkHolder;
import net.NetNode;

class PlayerChannelContainer implements IChunkHolder extends NetNode {

	@:s var chunks : NSIntMap<NSIntMap<Chunk>> = new NSIntMap();

	@:s var blocks : NSIntMap<NSIntMap<NSIntMap<Block>>> = new NSIntMap();

	#if !debug inline #end
	public function setChunk( x : Int, y : Int, chunk : Chunk ) {
		if ( chunks[y] == null ) chunks[y] = new NSIntMap();
		chunks[y][x] = chunk;

		for ( z => blockZ in chunk.blocks ) {
			for ( y => blockY in blockZ ) {
				for ( x => blockX in blockY ) {
					setBlock( x, y, z, blockX );
				}
			}
		}
	}

	public inline function removeChunk( x : Int, y : Int ) {
		var chunk = chunks[y].remove( x );

		for ( z => blockZ in chunk.blocks ) {
			for ( y => blockY in blockZ ) {
				for ( x => blockX in blockY ) {
					removeBlock( x, y, z );
				}
			}
		}
	}

	public inline function hasChunkAt( x : Int, y : Int ) : Bool {
		if ( chunks[y] == null || chunks[y][x] == null ) return false;
		return true;
	}

	public inline function setBlock( x : Int, y : Int, z : Int, block : Block ) {
		if ( blocks[z] == null ) blocks[z] = new NSIntMap();
		if ( blocks[z][y] == null ) blocks[z][y] = new NSIntMap();
		blocks[z][y][x] = block;
	}

	public inline function removeBlock( x : Int, y : Int, z : Int ) {
		blocks[z][y][x] = null;
	}

	override function alive() {
		super.alive();

		chunks.onSet.add( ( y, intMap : NSIntMap<Chunk> ) -> {
			intMap.onRemove.add( ( key : Int, chunk : Chunk ) -> {
				chunk.view.val.destroy();
			} );
		} );
	}
}
