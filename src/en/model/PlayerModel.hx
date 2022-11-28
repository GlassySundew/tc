package en.model;

import hxbit.NetworkSerializable;
import en.player.Player.PlayerActionState;
import net.PrimNS;
import ui.core.InventoryGrid;
import ui.player.ItemCursorHolder;
import net.NetNode;

class PlayerModel implements NetworkSerializable {

	@:s public var nickname = "";
	@:s public var actionState : PrimNS<PlayerActionState> = new PrimNS<PlayerActionState>( Idle );

	public function new() {
		enableAutoReplication = true;
	}
}
