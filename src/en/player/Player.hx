package en.player;

import ch3.scene.TileSprite;
import en.items.Blueprint;
import format.tmx.Data.TmxObject;
import h2d.Tile;
import h3d.mat.Texture;
import hxbit.NetworkSerializable;
import hxbit.Serializer;
import hxd.Key;
import seedyrng.Random;
import ui.Navigation;
import ui.PauseMenu;
import ui.domkit.TextLabelComp;
import ui.player.PlayerUI;

class Player extends Entity {
	public static var inst : Player;

	public var state : PlayerState;

	var nicknameMesh : TileSprite;

	@:s public var nickname : String;
	public var ui : PlayerUI;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var belt : dn.heaps.Controller.ControllerAccess;

	public var holdItem(default, set) : en.Item;

	// celestial
	/** generated name of the asteroid **/
	@:s public var residesOnId(default, set) : String;
	@:s public var travelling : Bool;
	@:s public var onBoard : Bool;

	function set_residesOnId( v : String ) {
		return residesOnId = v;
	}

	public function putItemInCursor( v : Item ) {
		for ( e in Entity.ALL ) if ( e.cellGrid != null ) e.cellGrid.grid.enableGrid();
		v.x = 13;
		v.y = 13;
		Cursors.passObjectForCursor(v);
		v.visible = false;
		v.onPlayerHold.dispatch();
		v.containerEntity = this;
		Boot.inst.s2d.addChild(v);
	}

	inline function set_holdItem( v : en.Item ) {
		Cursors.removeObjectFromCursor(holdItem);

		if ( holdItem != null ) holdItem.onPlayerRemove.dispatch();
		if ( v == null ) {
			if ( holdItem != null ) {
				holdItem.visible = true;
			}
			for ( e in Entity.ALL ) if ( e.cellGrid != null ) e.cellGrid.grid.disableGrid();
		}

		if ( holdItem != null && !holdItem.isDisposed )
			holdItem.visible = true;

		if ( v != null && !v.isInBelt() ) {
			putItemInCursor(v);
			Player.inst.ui.belt.deselectCells();
		}

		return holdItem = v;
	}

	public function new( x : Float, z : Float, ?tmxObj : TmxObject, ?uid : Int, ?nickname : String ) {
		this.nickname = nickname;
		this.uid = uid;
		inst = this;
		travelling = false;
		onBoard = true;

		super(x, z, tmxObj);

		// new game here, thus setting player to a random asteroid in 0, 0 asteroid chunk, idk what to make it in multiplayer
		if ( Navigation.inst.fields.length > 0 ) {
			var r = new Random();
			r.setStringSeed(Game.inst.seed);
			residesOnId = r.choice(Navigation.inst.fields[0].targets).id;
		}
	}

	override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		spr = new HSprite(Assets.player, entParent);
		#if !headless
		ca = Main.inst.controller.createAccess("player");
		belt = Main.inst.controller.createAccess("belt");
		#end

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
			spr.anim.registerStateAnim("walk_" + dir.dir, dir.prio, (1 / 60 / 0.16), function () return isMoving() && this.dir == i);
			spr.anim.registerStateAnim("idle_" + dir.dir, dir.prio, (1 / 60 / 0.16), function () return !isMoving() && this.dir == i);
		}
		super.init(x, z, tmxObj);

		#if !headless
		// public var cellGrid : InventoryGrid;

		if ( inst == this ) ui = new PlayerUI(Game.inst.root);

		#if depth_debug
		mesh.renewDebugPts();
		#end
		#end

		// Костыльный фикс бага с бампом игрока при старте уровня
		lock(30);

		#if headless
		enableReplication = true;
		#end

		Game.inst.delayer.addF(() -> {
			checkTeleport();
		}, 1);
	}

	public static var onGenerationCallback : Void -> Void;
	/** 
		shows teleport button if the map is already generated or add callback to show butotn
		@param acceptTmxPlayerCoord if true, then player's position will be set as the player objct in tmx entities layer, false is regular
	**/
	public function checkTeleport() {

		// search for a target to put a link to in a teleport button
		var target = Navigation.inst.getTargetById(residesOnId);

		onGenerationCallback = () -> {
			if ( onBoard )
				ui.prepareTeleportDown(target.bodyLevelName, true);
			else
				ui.prepareTeleportUp("ship_pascal", false);
		}

		if ( ui != null ) if ( target != null &&
			target.generator != null &&
			target.generator.mapIsGenerating ) {
			target.generator.onGeneration.add(onGenerationCallback);
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

	override function set_netX( v : Float ) : Float {
		if ( inst != this ) {
			footX = v;
		}
		return super.set_netX(v);
	}

	override function set_netY( v : Float ) : Float {
		if ( inst != this ) {
			footY = v;
		}
		return super.set_netY(v);
	}

	override function customSerialize( ctx : Serializer ) {
		super.customSerialize(ctx);

		// holditem
		if ( holdItem != null && holdItem.isInCursor() ) {
			ctx.addString(Std.string(holdItem.cdbEntry));
			ctx.addInt(holdItem.amount);
		} else {
			ctx.addString("null");
			ctx.addInt(0);
		}
	}

	override function customUnserialize( ctx : Serializer ) {
		if ( inst == null ) inst = this;

		super.customUnserialize(ctx);

		// holditem
		var holdItemCdb = ctx.getString();
		var holdItemAmt = ctx.getInt();

		if ( holdItemCdb != "null" ) {
			Game.inst.delayer.addF(() -> {
				var item = Item.fromCdbEntry(Data.items.resolve(holdItemCdb).id, holdItemAmt);
				item.containerEntity = this;
				holdItem = item;
			}, 1);
		}
	}

	override public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable ) : Bool {
		// trace(clientSer == this && this == inst);
		// var player = cast(clientSer, Player);
		return clientSer == this;
	}

	override public function alive() {
		super.alive();
		enableReplication = true;

		init();
		GameClient.inst.applyTmxObjOnEnt(this);
		if ( uid == GameClient.inst.uid ) {
			inst = this;
			GameClient.inst.camera.target = this;
			GameClient.inst.camera.recenter();

			GameClient.inst.player = this;
			GameClient.inst.host.self.ownerObject = this;
			sprFrame = { group : "null", frame : 0 };
		}
		this.netX = netX;
		this.netY = netY;
		initNickname();
		syncFrames();
	}
	/**generate nickname text mesh**/
	public function initNickname() {
		var nicknameLabel = new TextLabelComp(nickname, Assets.fontPixel);
		var nicknameTex = new Texture(nicknameLabel.innerWidth, nicknameLabel.innerHeight + 10, [Target]);
		nicknameLabel.drawTo(nicknameTex);
		nicknameMesh = new TileSprite(Tile.fromTexture(nicknameTex), false, mesh);
		nicknameMesh.material.mainPass.setBlendMode(AlphaAdd);
		nicknameMesh.material.mainPass.enableLights = false;
		nicknameMesh.material.mainPass.depth(false, Less);
		nicknameMesh.scale(.5);
		nicknameMesh.z += 40;
		nicknameMesh.y += 1;
		@:privateAccess nicknameMesh.plane.ox = -nicknameLabel.innerWidth / 2;
	}

	public function disableGrids() {
		ui.inventory.cellGrid.grid.disableGrid();
	}

	public function enableGrids() {
		ui.inventory.cellGrid.grid.enableGrid();
	}

	override function dispose() {
		super.dispose();
		#if !headless
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
		ca.dispose();
		belt.dispose();

		holdItem.remove();
		holdItem = null;
		#end
	}

	// multiplayer
	function syncFrames() {
		if ( sprFrame != null ) {
			if ( spr.frame != sprFrame.frame || spr.groupName != sprFrame.group ) {
				if ( this == inst ) sprFrame = { group : spr.groupName, frame : spr.frame }; else if ( sprFrame == null ) sprFrame = {
					group : "null",
					frame : 0
				}
				else
					spr.set(sprFrame.group, sprFrame.frame);
			}
		}
	}

	override public function update() {
		super.update();

		#if !headless
		if ( inst == this ) {
			var leftDist = M.dist(0, 0, ca.lxValue(), ca.lyValue());
			var leftPushed = leftDist >= 0.3;
			var leftAng = Math.atan2(ca.lyValue(), ca.lxValue());
			if ( !isLocked() ) {
				if ( leftPushed ) {
					var s = 0.325 * leftDist;
					dx += Math.cos(leftAng) * s;
					dy += Math.sin(leftAng) * s;

					if ( ca.lxValue() < -0.3 && M.fabs(ca.lyValue()) < 0.6 ) dir = 4; else if ( ca.lyValue() < -0.3 && M.fabs(ca.lxValue()) < 0.6 ) dir = 6;
					else if ( ca.lxValue() > 0.3
						&& M.fabs(ca.lyValue()) < 0.6 ) dir = 0; else if ( ca.lyValue() > 0.3 && M.fabs(ca.lxValue()) < 0.6 ) dir = 2;

					if ( ca.lxValue() > 0.3 && ca.lyValue() > 0.3 ) dir = 1; else if ( ca.lxValue() < -0.3 && ca.lyValue() > 0.3 ) dir = 3; else
						if ( ca.lxValue() < -0.3
							&& ca.lyValue() < -0.3 ) dir = 5; else if ( ca.lxValue() > 0.3 && ca.lyValue() < -0.3 ) dir = 7;
				} else {
					dx *= Math.pow(0.6, tmod);
					dy *= Math.pow(0.6, tmod);
				}
			}
			netX = footX;
			netY = footY;
		}
		syncFrames();
		#end
	}

	override function postUpdate() {
		super.postUpdate();
		#if !headless
		if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();

		if ( ca.isKeyboardPressed(Key.R) ) {
			if ( holdItem != null && Std.isOfType(holdItem, Blueprint) && cast(holdItem, Blueprint).ghostStructure != null ) {
				cast(holdItem, Blueprint).ghostStructure.flipX();
			}
		}
		#end
	}

	override function updateCollisions() {
		super.updateCollisions();
		if ( !isLocked() ) checkCollsAgainstAll();
	}

	public function lockBelt() belt.lock();

	public function unlockBelt() belt.unlock();

	function checkBeltInputs() {
		if ( ca.isPressed(LT) ) {
			ui.inventory.toggleVisible();
		}

		if ( ca.isPressed(DPAD_UP) ) {
			ui.craft.toggleVisible();
		}

		if ( Key.isPressed(Key.NUMBER_1) ) ui.belt.selectCell(1);
		if ( Key.isPressed(Key.NUMBER_2) ) ui.belt.selectCell(2);
		if ( Key.isPressed(Key.NUMBER_3) ) ui.belt.selectCell(3);
		if ( Key.isPressed(Key.NUMBER_4) ) ui.belt.selectCell(4);
		if ( Key.isPressed(Key.NUMBER_5) ) ui.belt.selectCell(5);

		// Wheel scroll item selection
		var cellToSelect = ui.belt.selectedCellNumber;
		if ( belt.isKeyboardPressed(Key.MOUSE_WHEEL_DOWN) ) cellToSelect++;
		if ( belt.isKeyboardPressed(Key.MOUSE_WHEEL_UP) ) cellToSelect--;
		if ( cellToSelect != ui.belt.selectedCellNumber ) {
			if ( cellToSelect < 1 ) cellToSelect = ui.belt.beltSlots.length;
			if ( cellToSelect > ui.belt.beltSlots.length ) cellToSelect = 1;
			ui.belt.selectCell(cellToSelect);
		}

		if ( ca.selectPressed() ) {
			Game.inst.pause();
			Game.inst.pauseCycle = true;
			new PauseMenu();
		}

		if ( ca.yPressed() ) {
			// Q
			if ( holdItem != null && !holdItem.isDisposed ) {
				if ( Key.isDown(Key.CTRL) ) {

					// dropping whole stack
					dropItem(Item.fromCdbEntry(holdItem.cdbEntry, holdItem.amount), angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
					holdItem.amount = 0;
					holdItem = null;
				} else {
					// dropping 1 item
					dropItem(Item.fromCdbEntry(holdItem.cdbEntry, 1), angToPxFree(Level.inst.cursX, Level.inst.cursY), 2.3);
					holdItem.amount--;
				}
				if ( holdItem == null || holdItem.isDisposed )
					Player.inst.ui.belt.deselectCells();
			}

			if ( holdItem != null
				&& holdItem.isInCursor() )
				holdItem = holdItem;
		}
	}
}
