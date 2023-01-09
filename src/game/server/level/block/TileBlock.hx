package game.server.level.block;

import format.tmx.Data;

class TileBlock extends Block {

	@:s public var tileGid : Int;
	@:s public var tileset : TmxTileset;

	public function new( ?parent : Chunk ) {
		super( parent );
	}
}
