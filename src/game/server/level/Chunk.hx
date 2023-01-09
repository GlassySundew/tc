package game.server.level;

import net.NSArray;
import game.server.level.block.Block;
import net.NetNode;

class Chunk extends NetNode {

	@:s var blocks : NSArray<NSArray<NSArray<Block>>> = new NSArray();

	public function new() {
		super();
		enableAutoReplication = true;
	}

	inline function validateAccess( x : Int, y : Int, z : Int ) {
		if ( blocks[z] == null ) blocks[z] = new NSArray();
		if ( blocks[z][y] == null ) blocks[z][y] = new NSArray();
	}

	public inline function getBlock( x : Int, y : Int, z : Int ) : Block {
		validateAccess( x, y, z );
		return blocks[z][y][x];
	}

	public function setBlock( x : Int, y : Int, z : Int, block : Block ) {
		validateAccess( x, y, z );
		blocks[z][y][x] = block;
	}
}
