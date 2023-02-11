package game.server.level;

import hxbit.NetworkHost;
import hxbit.NetworkSerializable.NetworkSerializer;
import core.VO;
import game.client.level.ChunkView;
import net.NSIntMap;
import en.Entity;
import net.NSArray;
import game.server.level.block.Block;
import net.NetNode;

class Chunk extends NetNode {

	public var blocks : Map<Int, Map<Int, Map<Int, Block>>> = new Map();
	@:s var entities : NSArray<Entity> = new NSArray();

	public var x : Int;
	public var y : Int;
	public var view : VO<ChunkView> = new VO();

	public function new() {
		super();
		enableAutoReplication = true;
	}

	override function alive() {
		view.val = new ChunkView();
		super.alive();
	}

	inline function validateAccess( x : Int, y : Int, z : Int ) {
		if ( blocks[z] == null ) blocks[z] = new Map();
		if ( blocks[z][y] == null ) blocks[z][y] = new Map();
	}

	public inline function getBlock( x : Int, y : Int, z : Int ) : Block {
		validateAccess( x, y, z );
		return blocks[z][y][x];
	}

	public function setBlock( x : Int, y : Int, z : Int, block : Block ) {
		validateAccess( x, y, z );
		blocks[z][y][x] = block;
		block.chunk = this;
	}

	override function disconnect(
		host : NetworkHost,
		ctx : NetworkSerializer,
		?finalize : Bool
	) {
		super.disconnect( host, ctx, finalize );

		var testMap = new Map<Chunk, Bool>();

		for ( blockZ in blocks ) {
			for ( blockY in blockZ ) {
				for ( blockX in blockY ) {
					blockX.disconnect( host, ctx, finalize );
				}
			}
		}
	}
}
