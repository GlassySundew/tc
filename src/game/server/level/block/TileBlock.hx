package game.server.level.block;

import format.tmx.Data;
import game.client.level.LUTBlockView;
import game.client.level.LevelView;
import oimo.common.Vec3;
import util.oimo.OimoUtil;

using util.Extensions.TmxPropertiesExtension;

class TileBlock extends Block {

	@:s public var tileGid : Int;
	@:s public var tileset : TmxTileset;

	@:s public var depthOff : Int = 0;

	public function new( ?parent : Chunk ) {
		super( parent );
	}

	override function createView() {
		var type = tileset.properties.getProp( PTString, "type" );
		switch( type ) {
			case BlockType.LUT:
				chunk.view.onAppear( chunkView -> {
					view = new LUTBlockView( this, chunkView );
				} );
			default:
				trace( "unsupported block type " + type );
		}
	}

	override function createPhysics() {
		OimoUtil.addBox(
			LevelView.inst.world,
			new Vec3(
				x + ( tileset.tileHeight >> 1 ),
				y + ( tileset.tileHeight >> 1 ),
				z + ( tileset.tileHeight + 1 ) / 2
			),
			new Vec3(
				tileset.tileHeight >> 1,
				tileset.tileHeight >> 1,
				( tileset.tileHeight + 1 ) / 2
			),
			true
		);
	}
}
