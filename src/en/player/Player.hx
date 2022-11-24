package en.player;

import net.PrimNS;
import oimo.dynamics.rigidbody.RigidBody;
import dn.M;
import dn.heaps.input.ControllerAccess;
import dn.heaps.slib.HSprite;
import en.items.Blueprint;
import en.spr.EntitySprite;
import format.tmx.Data.TmxObject;
import game.client.ControllerAction;
import game.client.GameClient;
import game.client.level.Level;
import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import hxbit.Serializer;
import hxd.Key;
import net.ClientController;
import net.ClientToServer.AClientToServer;
import oimo.common.Vec3;
import ui.Navigation;
import ui.core.InventoryGrid;
import ui.player.ItemCursorHolder;
import ui.player.PlayerUI;
import utils.Assets;
import utils.Util;
import utils.tools.Settings;

using en.util.EntityUtil;

enum abstract PlayerActionState( String ) from String to String {

	var Running = "Running";
	var Idle = "Idle";
}

class Player extends Entity {

	public static var inst : Player;

	public var state : PlayerState;

	public var pui : PlayerUI;

	public var ca : ControllerAccess<ControllerAction>;
	public var belt : ControllerAccess<ControllerAction>;

	public var clientController : ClientController;

	/** generated name of the asteroid **/
	@:s public var residesOnId( default, set ) : String;
	@:s public var travelling : Bool;
	@:s public var onBoard : Bool;
	@:s public var nickname : String;
	@:s public var uid : Int;
	@:s public var sprGroup : String;

	@:s public var holdItem : ItemCursorHolder;
	@:s public var actionState : PrimNS<PlayerActionState>;

	public static final speed = 0.325;

	var holdItemSpr : HSprite;

	function set_residesOnId( v : String ) {
		return residesOnId = v;
	}

	public function new( x = 0., y = 0., z = 0., tmxObj : TmxObject, nickname : String, uid : Int, clientController : ClientController ) {
		this.nickname = nickname;
		this.uid = uid;
		this.clientController = clientController;
		travelling = false;
		onBoard = true;

		actionState = new PrimNS<PlayerActionState>( Idle );
		inventory = new InventoryGrid( 5, 6, PlayerInventory, this );
		holdItem = new ItemCursorHolder( this );

		super( x, y, z, tmxObj );

		actionState.syncBack = //
			footX.syncBack = //
				footY.syncBack = //
					footZ.syncBack = //
						dir.syncBack = //
							false;
		actionState.syncBackOwner = //
			footX.syncBackOwner = //
				footY.syncBackOwner = //
					footZ.syncBackOwner = //
						dir.syncBackOwner = //
							clientController;

		lock( 30 );
	}

	override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super.init( x, y, z, tmxObj );
	}

	public override function alive() {
		eSpr = new EntitySprite(
			this,
			Assets.player,
			Util.hollowScene
		);
		ca = Main.inst.controller.createAccess();
		belt = Main.inst.controller.createAccess();

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
				() -> return this.dir.val == i && actionState.val == Running
			);
			eSpr.spr.anim.registerStateAnim( "idle_" + dir.dir, dir.prio, ( 1 / 60 / 0.16 ),
				() -> return this.dir.val == i && actionState.val == Idle
			);
		}

		super.alive();

		if ( uid == net.Client.inst.uid ) {
			inst = this;
			pui = new PlayerUI( GameClient.inst.root, this );
			GameClient.inst.cameraProc.camera.targetEntity.val = this;
			GameClient.inst.cameraProc.camera.recenter();
			GameClient.inst.player = this;
		}
		eSpr.initTextLabel( nickname );
	}

	override function applyTmx() {
		super.applyTmx();

		if ( rigidBody != null ) {
			rigidBody.setRotationFactor( new Vec3( 0, 0, 0 ) );

			if ( inst == this ) {
				contactCb.postSolveSign.add( ( c ) -> {
					forceRBCoords = true;
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
		host.unregister( actionState, ctx, finalize );
		host.unregister( holdItem, ctx, finalize );
	}

	override public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		return GameClient.inst != null ? Main.inst.clientController == clientSer : cast( clientSer, ClientController ).player == this;
	}

	public static var onGenerationCallback : Void -> Void;

	/** 
		shows teleport button if the map is already generated or add callback to show butotn
		@param acceptTmxPlayerCoord if true, then player's position will be set as the player objct in tmx entities layer, false is regular
	**/
	public function checkTeleport() {

		// search for a target to put a link to in a teleport button
		var target = Navigation.serverInst.getTargetById( residesOnId );

		onGenerationCallback = () -> {
			if ( onBoard )
				pui.prepareTeleportDown( target.bodyLevelName, true );
			else
				pui.prepareTeleportUp( "ship_pascal", false );
		}

		if ( pui != null ) if ( target != null &&
			target.generator != null &&
			target.generator.mapIsGenerating ) {
			target.generator.onGeneration.add( onGenerationCallback );
		} else if ( target != null &&
			target.generator != null ) {
			onGenerationCallback();
		}
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

			holdItem.onSetItem.remove( attachHoldItemToSpr );
			holdItem = null;
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
					dx += Math.cos( leftAng ) * s;
					dy -= Math.sin( leftAng ) * s;

					if ( lx < -0.3 && M.fabs( ly ) < 0.6 ) dir.val = 4;
					else if ( ly < -0.3 && M.fabs( lx ) < 0.6 ) dir.val = 6;
					else if ( lx > 0.3 && M.fabs( ly ) < 0.6 ) dir.val = 0;
					else if ( ly > 0.3 && M.fabs( lx ) < 0.6 ) dir.val = 2;

					if ( lx > 0.3 && ly > 0.3 ) dir.val = 1;
					else if ( lx < -0.3 && ly > 0.3 ) dir.val = 3;
					else if ( lx < -0.3 && ly < -0.3 ) dir.val = 5;
					else if ( lx > 0.3 && ly < -0.3 ) dir.val = 7;
				} else {
					dx *= Math.pow( 0.6, tmod );
					dy *= Math.pow( 0.6, tmod );
				}
			}
			actionState.val = isMoving ? Running : Idle;
		}
		if ( rigidBody != null ) {
			if ( inst == this ) {
				rigidBody._velX = dx * tmod / Boot.inst.deltaTime;
				rigidBody._velY = dy * tmod / Boot.inst.deltaTime;
				rigidBody._velZ = dz * tmod / Boot.inst.deltaTime;
				if ( dx != 0 || dy != 0 || dz != 0 ) rigidBody.wakeUp();
			} else {
				rigidBody.setPosition( new Vec3( footX.val, footY.val, footZ.val ) );
			}
		}
		if ( inst != null && actionState.val == Running ) onMove.dispatch();

		super.update();
	}

	override function postUpdate() {
		super.postUpdate();

		// if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();

		if ( ca.isKeyboardPressed( Key.R ) ) {
			if (
				holdItem != null
				&& Std.isOfType( holdItem, Blueprint )
				&& cast( holdItem, Blueprint ).ghostStructure != null
			) {
				cast( holdItem, Blueprint ).ghostStructure.flipX();
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
			if ( holdItem != null ) {
				if ( Key.isDown( Key.CTRL ) ) {

					// dropping whole stack
					dropItem( Item.fromCdbEntry( holdItem.item.cdbEntry, this, holdItem.item.amount ), angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					holdItem.item.amount = 0;
					holdItem = null;
				} else {
					// dropping 1 item
					dropItem( Item.fromCdbEntry( holdItem.item.cdbEntry, this, 1 ), angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					holdItem.item.amount--;
				}
				if ( holdItem == null ) {

					Player.inst.pui.belt.deselectCells();
				}
			}
		}
	}
}
