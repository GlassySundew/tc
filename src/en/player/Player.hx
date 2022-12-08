package en.player;

import en.model.InventoryModel;
import en.model.PlayerModel;
import net.PrimNS;
import oimo.dynamics.rigidbody.RigidBody;
import dn.M;
import dn.heaps.input.ControllerAccess;
import dn.heaps.slib.HSprite;
import en.items.Blueprint;
import en.spr.EntityView;
import format.tmx.Data.TmxObject;
import game.client.ControllerAction;
import game.client.GameClient;
import game.client.level.Level;
import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import hxbit.Serializer;
import hxd.Key;
import net.ClientController;
import oimo.common.Vec3;
import ui.Navigation;
import ui.core.InventoryGrid;
import ui.player.ItemCursorHolder;
import ui.player.PlayerUI;
import util.Assets;
import util.Util;
import util.tools.Settings;

using en.util.EntityUtil;

enum abstract PlayerActionState( String ) from String to String {

	var Running = "Running";
	var Idle = "Idle";
}

@:keep
class Player extends Entity {

	public static var inst : Player;

	public var pui : PlayerUI;
	public var ca : ControllerAccess<ControllerAction>;
	public var belt : ControllerAccess<ControllerAction>;

	/** server-side only **/
	public var clientController( default, set ) : ClientController;

	function set_clientController( cc : ClientController ) : ClientController {
		clientController = cc;

		playerModel.actionState.syncBackOwner = //
			model.footX.syncBackOwner = //
				model.footY.syncBackOwner = //
					model.footZ.syncBackOwner = //
						model.dir.syncBackOwner = //
							clientController;
		return cc;
	}

	/** generated name of the asteroid **/
	@:s public var playerModel : PlayerModel;
	@:s public var inventoryModel : InventoryModel;
	@:s public var sprGroup : String;

	public static final speed = 0.325;
	public static var onGenerationCallback : Void -> Void;

	var holdItemSpr : HSprite;

	public function new( tmxObj : TmxObject ) {
		super( tmxObj );

		playerModel = new PlayerModel();
		inventoryModel = new InventoryModel();

		inventoryModel.holdItem = new ItemCursorHolder( this );

		playerModel.actionState.syncBack = //
			model.footX.syncBack = //
				model.footY.syncBack = //
					model.footZ.syncBack = //
						model.dir.syncBack = //
							false;

		lock( 30 );
	}

	override function init() {
		super.init();
	}

	public override function alive() {
		ca = Main.inst.controller.createAccess();
		belt = Main.inst.controller.createAccess();

		if ( model.controlId == net.Client.inst.uid ) {
			inst = this;
			pui = new PlayerUI( GameClient.inst.root, this );
			GameClient.inst.cameraProc.camera.targetEntity.val = this;
			GameClient.inst.cameraProc.camera.recenter();
			GameClient.inst.player = this;
		}

		super.alive();

		eSpr.initTextLabel( playerModel.nickname );

		for ( i => dir in [
			{ dir : "right", prio : 0 },
			{ dir : "up_right", prio : 1 },
			{ dir : "up", prio : 0 },
			{ dir : "up_left", prio : 1 },
			{ dir : "left", prio : 0 },
			{ dir : "down_left", prio : 1 },
			{ dir : "down", prio : 0 },
			{ dir : "down_right", prio : 1 }
		] ) {
			eSpr.spr.anim.registerStateAnim( "walk_" + dir.dir, dir.prio, ( 1 / 60 / 0.16 ),
				() -> return model.dir.val == i && playerModel.actionState.val == Running
			);
			eSpr.spr.anim.registerStateAnim( "idle_" + dir.dir, dir.prio, ( 1 / 60 / 0.16 ),
				() -> return model.dir.val == i && playerModel.actionState.val == Idle
			);
		}
	}

	override function createView() {
		eSpr = new EntityView(
			this,
			Assets.player,
			Util.hollowScene
		);
	}

	override function applyTmx() {
		super.applyTmx();

		if ( model.rigidBody != null ) {
			model.rigidBody.setRotationFactor( new Vec3( 0, 0, 0 ) );

			if ( inst == this ) {
				model.contactCb.postSolveSign.add( ( c ) -> {
					model.forceRBCoords = true;
				} );
			}
		}
	}

	function attachHoldItemToSpr( item : Item ) {
		if ( holdItemSpr != null )
			eSpr.drawToBoolStack.addLambda(
				() -> return ( holdItemSpr.visible = item != null )
			);

		if ( item != null ) {
			if ( holdItemSpr == null )
				holdItemSpr = new HSprite( Assets.items, eSpr.spr );
			holdItemSpr.set( Data.item.get( item.cdbEntry ).atlas_name );
		}
	}

	override function unreg(
		host : NetworkHost,
		ctx : NetworkSerializer,
		?finalize
	) @:privateAccess {
		super.unreg( host, ctx );
		// host.unregister( actionState, ctx, finalize );
		// host.unregister( holdItem, ctx, finalize );
	}

	override public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return GameClient.inst != null ? Main.inst.clientController == clientSer : cast( clientSer, ClientController ).player == this;
	}

	/* записывает настройки  */
	public function saveSettings() {
		if ( inst == this ) {
			if ( Player.inst.pui.inventory != null ) {
				Settings.params.inventoryCoordRatio.x = Player.inst.pui.inventory.win.x / Main.inst.w();
				Settings.params.inventoryCoordRatio.y = Player.inst.pui.inventory.win.y / Main.inst.h();
				Settings.params.inventoryVisible = pui.inventory.win.visible;
			}

			if ( Player.inst.pui.craft != null ) {
				Settings.params.playerCrafting.x = Player.inst.pui.craft.win.x / Main.inst.w();
				Settings.params.playerCrafting.y = Player.inst.pui.craft.win.y / Main.inst.h();
				Settings.params.playerCraftingVisible = pui.craft.win.visible;
			}
		}
	}

	override function dispose() {
		super.dispose();
		if ( inst == this ) {
			saveSettings();
			inst = null;
		}

		if ( pui != null ) {
			pui.destroy();
			pui = null;
		}

		if ( GameClient.inst != null ) {
			ca.dispose();
			belt.dispose();

			inventoryModel.holdItem.onSetItem.remove( attachHoldItemToSpr );
			inventoryModel.holdItem = null;
		}
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override public function update() {

		if ( inst == this ) {
			var lx = ca.getAnalogValue2( MoveLeft, MoveRight );
			var ly = ca.getAnalogValue2( MoveDown, MoveUp );

			var leftDist = M.dist( 0, 0, lx, ly );
			var leftPushed = leftDist >= 0.3;
			var leftAng = Math.atan2( ly, lx );
			if ( !isLocked() ) {
				if ( leftPushed ) {
					var s = leftDist * speed;
					model.dx += Math.cos( leftAng ) * s;
					model.dy -= Math.sin( leftAng ) * s;

					if ( lx < -0.3 && M.fabs( ly ) < 0.6 ) model.dir.val = 4;
					else if ( ly < -0.3 && M.fabs( lx ) < 0.6 ) model.dir.val = 6;
					else if ( lx > 0.3 && M.fabs( ly ) < 0.6 ) model.dir.val = 0;
					else if ( ly > 0.3 && M.fabs( lx ) < 0.6 ) model.dir.val = 2;

					if ( lx > 0.3 && ly > 0.3 ) model.dir.val = 1;
					else if ( lx < -0.3 && ly > 0.3 ) model.dir.val = 3;
					else if ( lx < -0.3 && ly < -0.3 ) model.dir.val = 5;
					else if ( lx > 0.3 && ly < -0.3 ) model.dir.val = 7;
				} else {
					model.dx *= Math.pow( 0.6, tmod );
					model.dy *= Math.pow( 0.6, tmod );
				}
			}
			playerModel.actionState.val = isMoving ? Running : Idle;
		}
		if ( model.rigidBody != null ) {
			if ( inst == this ) {
				model.rigidBody._velX = model.dx * tmod / Boot.inst.deltaTime;
				model.rigidBody._velY = model.dy * tmod / Boot.inst.deltaTime;
				model.rigidBody._velZ = model.dz * tmod / Boot.inst.deltaTime;
				if ( model.dx != 0 || model.dy != 0 || model.dz != 0 )
					model.rigidBody.wakeUp();
			} else {
				model.rigidBody.setPosition(
					new Vec3(
						model.footX.val,
						model.footY.val,
						model.footZ.val
					)
				);
			}
		}
		if ( inst != null && playerModel.actionState.val == Running ) onMove.dispatch();

		super.update();
	}

	override function postUpdate() {
		super.postUpdate();

		// if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();

		if ( ca.isKeyboardPressed( Key.R ) ) {
			if (
				inventoryModel.holdItem != null
				&& Std.isOfType( inventoryModel.holdItem, Blueprint )
				&& cast( inventoryModel.holdItem, Blueprint ).ghostStructure != null
			) {
				cast( inventoryModel.holdItem, Blueprint ).ghostStructure.flipX();
			}
		}
	}

	public function lockBelt() belt.lock();

	public function unlockBelt() belt.unlock();

	function checkBeltInputs() {
		if ( ca.isPressed( ToggleInventory ) ) {
			pui.inventory.toggleVisible();
		}

		if ( ca.isPressed( ToggleCraftingMenu ) ) {
			pui.craft.toggleVisible();
		}

		if ( Key.isPressed( Key.NUMBER_1 ) ) pui.belt.selectCell( 1 );
		if ( Key.isPressed( Key.NUMBER_2 ) ) pui.belt.selectCell( 2 );
		if ( Key.isPressed( Key.NUMBER_3 ) ) pui.belt.selectCell( 3 );
		if ( Key.isPressed( Key.NUMBER_4 ) ) pui.belt.selectCell( 4 );
		if ( Key.isPressed( Key.NUMBER_5 ) ) pui.belt.selectCell( 5 );

		// Wheel scroll item selection
		if ( pui != null ) {
			var cellToSelect = pui.belt.selectedCellNumber;
			if ( belt.isKeyboardPressed( Key.MOUSE_WHEEL_DOWN ) ) cellToSelect++;
			if ( belt.isKeyboardPressed( Key.MOUSE_WHEEL_UP ) ) cellToSelect--;
			if ( cellToSelect != pui.belt.selectedCellNumber ) {
				if ( cellToSelect < 1 ) cellToSelect = pui.belt.beltSlots.length;
				if ( cellToSelect > pui.belt.beltSlots.length ) cellToSelect = 1;
				pui.belt.selectCell( cellToSelect );
			}
		}

		if ( ca.isPressed( DropItem ) ) {
			// Q
			if ( inventoryModel.holdItem != null ) {
				if ( Key.isDown( Key.CTRL ) ) {

					// dropping whole stack
					dropItem(
						Item.fromCdbEntry(
							inventoryModel.holdItem.item.cdbEntry,
							this,
							inventoryModel.holdItem.item.amount
						),
						this.angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					inventoryModel.holdItem.item.amount = 0;
					inventoryModel.holdItem = null;
				} else {
					// dropping 1 item
					dropItem(
						Item.fromCdbEntry(
							inventoryModel.holdItem.item.cdbEntry,
							this,
							1 ),
						this.angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					inventoryModel.holdItem.item.amount--;
				}
				if ( inventoryModel.holdItem == null ) {

					Player.inst.pui.belt.deselectCells();
				}
			}
		}
	}
}
