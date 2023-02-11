package game.server.level.block;

import game.client.level.BlockView;
import net.NetNode;

class Block extends NetNode {

	@:s public var x : Int;
	@:s public var y : Int;
	@:s public var z : Int;
	@:s public var chunk : Chunk;

	public var view : BlockView;

	public function new( ?parent : Chunk ) {
		super( parent );
	}

	override function alive() {
		super.alive();
		createView();
		createPhysics();
	}

	public function createView() {}

	public function createPhysics() {}
}
