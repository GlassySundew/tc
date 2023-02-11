package game.client.level;

import i.IDestroyable;
import h2d.domkit.Object;

class BlockView implements IDestroyable {

	public function new( chunkView : ChunkView ) {
		chunkView.addBlockView( this );
	}

	public function destroy() {}
}
