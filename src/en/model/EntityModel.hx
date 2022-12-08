package en.model;

import ui.player.ItemCursorHolder;
import util.Const;
import en.collide.EntityContactCallback;
import ui.core.InventoryGrid;
import util.Direction;
import ui.core.InventoryGrid.InventoryCellFlowGrid;
import net.Client;
import dn.Tweenie;
import en.spr.EntityView;
import game.client.GameClient;
import oimo.dynamics.rigidbody.RigidBody;
import format.tmx.Data.TmxObject;
import net.PrimNS;
import game.server.ServerLevel;
import net.NetNode;

class EntityModel extends NetNode {

	/** used for players to control entities **/
	@:s public var controlId : Int;
	@:s public var cdb : Data.EntityKind;
	@:s public var level( default, set ) : ServerLevel;
	@:s public var dir : PrimNS<Direction>;
	@:s public var footX : PrimNS<Float>;
	@:s public var footY : PrimNS<Float>;
	@:s public var footZ : PrimNS<Float>;
	@:s public var tmxObj : TmxObject;
	@:s public var flippedX : Bool = false;

	public var rigidBody( default, set ) : RigidBody;

	function set_rigidBody( rb : RigidBody ) : RigidBody {
		return rigidBody = rb;
	}

	public var contactCb : EntityContactCallback;

	function set_level( v : ServerLevel ) {
		return level = v;
	}

	public var forceRBCoords = false;

	public var dx = 0.;
	public var dy = 0.;
	public var dz = 0.;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var bumpReduction = 0.;

	public var sqlId : Null<Int>;

	public var cd : dn.Cooldown;
	public var tw : Tweenie;

	public var tmxAppliedInvalidate = false;

	public var flippedOnClient = false;

	public var onMoveInvalidate = false;

	public function new() {
		super();
		init();

		footX = new PrimNS( 0. );
		footY = new PrimNS( 0. );
		footZ = new PrimNS( 0. );
		dir = new PrimNS( Bottom );
	}

	override function init() {
		super.init();
		cd = new dn.Cooldown( Const.FPS );
		tw = new Tweenie( Const.FPS );
	}

	public override function alive() {
		init();
	}
}
