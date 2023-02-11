package game.client.level;

import i.IDestroyable;
import h2d.Object;

class ChunkView implements IDestroyable {

	var blockViews : Array<BlockView> = [];

	public function new() {}

	public function addBlockView( blockView : BlockView ) {
		blockViews.push( blockView );
	}

	public function destroy() {
		for ( view in blockViews ) {
			view.destroy();
		}
	}
}
