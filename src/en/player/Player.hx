package en.player;

import dn.heaps.input.ControllerAccess;
import net.ClientToServer.AClientToServer;
import net.ClientController;
import haxe.CallStack;
import ch3.scene.TileSprite;
import en.items.Blueprint;
import format.tmx.Data.TmxObject;
import h2d.Tile;
import h3d.mat.Texture;
import hxbit.Serializer;
import hxd.Key;
import ui.InventoryGrid;
import ui.ItemSprite;
import ui.Navigation;
import ui.PauseMenu;
import ui.domkit.TextLabelComp;
import ui.player.PlayerUI;

enum abstract PlayerActionState( String ) from String to String {

	var Running = "Running";
	var Idle = "Idle";
}

class Player extends Entity {

	public static var inst : Player;

	public var state : PlayerState;

	var nicknameMesh : TileSprite;

	@:s public var nickname : String;
	public var ui : PlayerUI;

	public var ca : ControllerAccess<ControllerAction>;
	public var belt : ControllerAccess<ControllerAction>;

	@:s public var holdItem( default, set ) : en.Item;

	@:s public var item : Item;
	@:s public var clientController : ClientController;

	@:s public var actionState : AClientToServer<PlayerActionState>;

	function set_holdItem( v : en.Item ) : Item {

		if ( holdItem != null ) {
			if ( holdItem.itemSprite != null )
				Cursors.removeObjectFromCursor( holdItem.itemSprite );
			holdItem.onPlayerRemove.dispatch();
		}

		if ( v == null ) {
			for ( e in Entity.ALL ) if ( e.cellGrid != null ) e.cellGrid.disableGrid();
		}

		if ( v != null /* && !itemInBelt(v) */ && v.itemSprite != null ) {
			trace( "putting item " + v.itemSprite, Server.inst, v == holdItem );
			// for( i in CallStack.callStack())
			// 	trace(i);

			putItemInCursor( v.itemSprite );
			Player.inst.ui.belt.deselectCells();
		}

		return holdItem = v;
	}

	public function putItemInCursor( v : ItemSprite ) {
		for ( e in Entity.ALL ) if ( e.cellGrid != null ) e.cellGrid.enableGrid();
		v.x = v.y = 5;
		Cursors.passObjectForCursor( v );
		v.item.onPlayerHold.dispatch();
	}

	/** generated name of the asteroid **/
	@:s public var residesOnId( default, set ) : String;
	@:s public var travelling : Bool;
	@:s public var onBoard : Bool;
	@:s public var uid : Int;
	@:s public var sprGroup : String;

	function set_residesOnId( v : String ) {
		return residesOnId = v;
	}

	public function new( x : Float, z : Float, ?tmxObj : TmxObject, ?nickname : String, ?uid : Int ) {
		this.nickname = nickname;
		this.uid = uid;
		travelling = false;
		onBoard = true;

		actionState = new AClientToServer<PlayerActionState>( Idle );

		inventory = new InventoryGrid( 5, 6, this );

		super( x, z, tmxObj );

		lock( 30 );

		// new game here, thus setting player to a random asteroid in 0, 0 asteroid chunk, idk what to make it in multiplayer

		// if ( Navigation.serverInst.fields.length > 0 ) {
		// var r = new Random();
		// 	r.setStringSeed(Server.inst.game.seed);
		// 	residesOnId = r.choice(Navigation.serverInst.fields[0].targets).id;
		// }

		// footX.clientToServerCond = footY.clientToServerCond = () -> return true;
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {

		super.init( x, z, tmxObj );
	}

	public override function alive() {
		// GameClient.inst.delayer.addF(() -> {
		// 	checkTeleport();
		// }, 1);

		// netX = footX;
		// netY = footY;

		spr = new HSprite( Assets.player, entParent );
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
			spr.anim.registerStateAnim( "walk_" + dir.dir, dir.prio, ( 1 / 60 / 0.16 ),
				() -> return this.dir == i && actionState.getValue() == Running
			);
			spr.anim.registerStateAnim( "idle_" + dir.dir, dir.prio, ( 1 / 60 / 0.16 ),
				() -> return this.dir == i && actionState.getValue() == Idle
			);
		}

		super.alive();

		#if depth_debug
		mesh.renewDebugPts();
		#end

		if ( uid == Client.inst.uid ) {
			inst = this;

			ui = new PlayerUI( GameClient.inst.root, this );
			GameClient.inst.camera.target = this;
			GameClient.inst.camera.recenter();

			GameClient.inst.player = this;

			sprFrame = { group : spr.groupName, frame : spr.frame };

			Main.inst.delayer.addF(() -> {
				actionState.clientToServerCond = footX.clientToServerCond = footY.clientToServerCond = () -> true;
			}, 1 );
		}

		initNickname();
		syncFrames();
	}

	override public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {

		// server
		// if ( clientController.player == this && op == SetField ) {
		// 	return false;
		// }

		return GameClient.inst != null ? Main.inst.clientController == clientSer : cast( clientSer, ClientController ).player == this;
	}

	/**generate nickname text mesh**/
	public function initNickname() {
		var nicknameLabel = new TextLabelComp( nickname, Assets.fontPixel );
		@:privateAccess nicknameLabel.sync( Boot.inst.s2d.ctx );

		var nicknameTex = new Texture( nicknameLabel.outerWidth + 20, nicknameLabel.outerHeight, [Target] );

		nicknameLabel.drawTo( nicknameTex );
		nicknameMesh = new TileSprite( Tile.fromTexture( nicknameTex ), false, mesh );
		nicknameMesh.material.mainPass.setBlendMode( AlphaAdd );
		nicknameMesh.material.mainPass.enableLights = false;
		nicknameMesh.material.mainPass.depth( false, LessEqual );
		nicknameMesh.scale( .5 );
		nicknameMesh.z += 40;
		nicknameMesh.y += 1;
		@:privateAccess nicknameMesh.plane.ox = (-nicknameLabel.outerWidth >> 1 ) + 2;
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
				ui.prepareTeleportDown( target.bodyLevelName, true );
			else
				ui.prepareTeleportUp( "ship_pascal", false );
		}

		if ( ui != null ) if ( target != null &&
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
			if ( Player.inst.ui.inventory != null ) {
				Settings.params.inventoryCoordRatio.x = Player.inst.ui.inventory.win.x / Main.inst.w();
				Settings.params.inventoryCoordRatio.y = Player.inst.ui.inventory.win.y / Main.inst.h();
				Settings.params.inventoryVisible = ui.inventory.win.visible;
			}

			if ( Player.inst.ui.craft != null ) {
				Settings.params.playerCrafting.x = Player.inst.ui.craft.win.x / Main.inst.w();
				Settings.params.playerCrafting.y = Player.inst.ui.craft.win.y / Main.inst.h();
				Settings.params.playerCraftingVisible = ui.craft.win.visible;
			}
		}
	}

	@:rpc( server )
	public function testItem() : Item {
		holdItem = Item.fromCdbEntry( iron, this, 1 );
		return holdItem;
	}

	public function itemInBelt( item : Item ) {
		return holdItem == item && holdItem.itemPresense == Belt;
	}

	public function itemInCursor( item : Item ) {
		return holdItem == item && holdItem.itemPresense == Cursor;
	}

	public function itemInInventory( item : Item ) {
		return holdItem == item && holdItem.itemPresense == Inventory;
	}

	public function disableGrids() {
		ui.inventory.cellGrid.disableGrid();
	}

	public function enableGrids() {
		ui.inventory.cellGrid.enableGrid();
	}

	override function dispose() {
		super.dispose();
		if ( inst == this ) {
			saveSettings();
			inst = null;
		}

		if ( ui != null ) {
			ui.destroy();
			ui = null;
		}

		if ( nicknameMesh != null ) {
			nicknameMesh.remove();
			nicknameMesh = null;
		}
		if ( GameClient.inst != null ) {
			ca.dispose();
			belt.dispose();

			if ( holdItem != null && holdItem.itemSprite != null )
				holdItem.itemSprite.remove();

			holdItem = null;
		}
	}

	// multiplayer
	function syncFrames() {
		if ( sprFrame != null ) {
			if ( spr.frame != sprFrame.frame || spr.groupName != sprFrame.group ) {
				if ( this == inst )
					sprFrame = {
						group : spr.groupName,
						frame : spr.frame
					};
				else if ( sprFrame == null )
					sprFrame = {
						group : "null",
						frame : 0
					}
				else
					spr.set( sprFrame.group, sprFrame.frame );
			}
		}
	}

	override function preUpdate() {

		super.preUpdate();
	}

	override public function update() {
		super.update();

		if ( inst == this ) {
			// calculateIsMoving();

			var lx = ca.getAnalogValue2( MoveLeft, MoveRight );
			var ly = ca.getAnalogValue2( MoveDown, MoveUp );

			var leftDist = M.dist( 0, 0, lx, ly );
			var leftPushed = leftDist >= 0.3;
			var leftAng = Math.atan2( ly, lx );
			if ( !isLocked() ) {
				if ( leftPushed ) {
					var s = 0.325 * leftDist;
					dx += Math.cos( leftAng ) * s;
					dy += Math.sin( leftAng ) * s;

					if ( lx < -0.3 && M.fabs( ly ) < 0.6 ) dir = 4; else if ( ly < -0.3 && M.fabs( lx ) < 0.6 ) dir = 6;
					else if ( lx > 0.3
						&& M.fabs( ly ) < 0.6 ) dir = 0; else if ( ly > 0.3 && M.fabs( lx ) < 0.6 ) dir = 2;

					if ( lx > 0.3 && ly > 0.3 ) dir = 1; else if ( lx < -0.3 && ly > 0.3 ) dir = 3; else
						if ( lx < -0.3
							&& ly < -0.3 ) dir = 5; else if ( lx > 0.3 && ly < -0.3 ) dir = 7;
				} else {
					dx *= Math.pow( 0.6, tmod );
					dy *= Math.pow( 0.6, tmod );
				}
			}

			actionState.setValue( isMoving ? Running : Idle );
		}

		syncFrames();
	}

	override function postUpdate() {
		super.postUpdate();

		if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();

		if ( ca.isKeyboardPressed( Key.R ) ) {
			if ( holdItem != null && Std.isOfType( holdItem, Blueprint ) && cast( holdItem, Blueprint ).ghostStructure != null ) {
				cast( holdItem, Blueprint ).ghostStructure.flipX();
			}
		}
	}

	override function updateCollisions() {
		if ( !isLocked() ) {
			super.updateCollisions();
			if ( inst == this ) checkCollsAgainstAll();
		}
	}

	public function lockBelt() belt.lock();

	public function unlockBelt() belt.unlock();

	function checkBeltInputs() {
		if ( ca.isPressed( ToggleInventory ) ) {
			ui.inventory.toggleVisible();
		}

		if ( ca.isPressed( ToggleCraftingMenu ) ) {
			ui.craft.toggleVisible();
		}

		if ( Key.isPressed( Key.NUMBER_1 ) ) ui.belt.selectCell( 1 );
		if ( Key.isPressed( Key.NUMBER_2 ) ) ui.belt.selectCell( 2 );
		if ( Key.isPressed( Key.NUMBER_3 ) ) ui.belt.selectCell( 3 );
		if ( Key.isPressed( Key.NUMBER_4 ) ) ui.belt.selectCell( 4 );
		if ( Key.isPressed( Key.NUMBER_5 ) ) ui.belt.selectCell( 5 );

		// Wheel scroll item selection
		if ( ui != null ) {
			var cellToSelect = ui.belt.selectedCellNumber;
			if ( belt.isKeyboardPressed( Key.MOUSE_WHEEL_DOWN ) ) cellToSelect++;
			if ( belt.isKeyboardPressed( Key.MOUSE_WHEEL_UP ) ) cellToSelect--;
			if ( cellToSelect != ui.belt.selectedCellNumber ) {
				if ( cellToSelect < 1 ) cellToSelect = ui.belt.beltSlots.length;
				if ( cellToSelect > ui.belt.beltSlots.length ) cellToSelect = 1;
				ui.belt.selectCell( cellToSelect );
			}
		}

		if ( ca.isPressed( DropItem ) ) {
			// Q
			if ( holdItem != null && !holdItem.isDisposed ) {
				if ( Key.isDown( Key.CTRL ) ) {

					// dropping whole stack
					dropItem( Item.fromCdbEntry( holdItem.cdbEntry, this, holdItem.amount ), angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					holdItem.amount = 0;
					holdItem = null;
				} else {
					// dropping 1 item
					dropItem( Item.fromCdbEntry( holdItem.cdbEntry, this, 1 ), angToPxFree( Level.inst.cursX, Level.inst.cursY ), 2.3 );
					holdItem.amount--;
				}
				if ( holdItem == null || holdItem.isDisposed ) {

					Player.inst.ui.belt.deselectCells();
				}
			}

			if ( holdItem != null
				&& holdItem.itemPresense == Cursor )
				holdItem = holdItem;
		}
	}
}
