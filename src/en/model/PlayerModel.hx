package en.model;

import hxbit.NetworkSerializable;
import en.player.Player.PlayerActionState;
import net.NSMutable;
import ui.core.InventoryGrid;
import ui.player.ItemCursorHolder;
import net.NetNode;

class PlayerModel implements NetworkSerializable {

	@:s public var nickname = "";
	@:s public var actionState : NSMutable<PlayerActionState> = new NSMutable<PlayerActionState>( Idle );

	public function new() {
		enableAutoReplication = true;
	}
}
