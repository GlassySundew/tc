package en.player;

import hxbit.Serializer;
import ch3.scene.TileSprite;
import en.items.Blueprint;
import format.tmx.Data.TmxObject;
import h2d.Tile;
import h3d.mat.Texture;
import hxbit.NetworkSerializable;
import hxd.Key;
import ui.InventoryGrid.CellGrid;
import ui.PauseMenu;
import ui.TextLabel;
import ui.Window;
import ui.player.Inventory;
import ui.player.PlayerUI;

class Player extends Entity {
	public static var inst : Player;

	public var state : PlayerState;

	var nicknameMesh : TileSprite;

	@:s public var nickname : String;
	public var ui : PlayerUI;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var itemsManager : dn.heaps.Controller.ControllerAccess;

	public var holdItem(default, set) : en.Item;

	inline function set_holdItem(v : en.Item) {
		if ( holdItem != null ) holdItem.onPlayerRemove.dispatch();
		if ( v == null ) {
			for (i in Inventory.ALL) i.invGrid.disableGrid();
		}
		if ( v != null && !v.isInBelt() ) {
			v.onPlayerHold.dispatch();
			Boot.inst.s2d.addChild(v);
			v.scaleX = v.scaleY = 2;
		}
		return holdItem = v;
	}

	public function new(x : Float, z : Float, ?tmxObj : TmxObject, ?uid : Int, ?nickname : String) {
		this.nickname = nickname;
		this.uid = uid;
		inst = this;

		super(x, z, tmxObj);
	}

	override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		spr = new HSprite(Assets.player, entParent);
		#if !headless
		ca = Main.inst.controller.createAccess("player");
		itemsManager = Main.inst.controller.createAccess("playerItemsManager");
		#end

		var direcs = [
			{dir : "right", prio : 0},
			{dir : "up_right", prio : 1},
			{dir : "up", prio : 0},
			{dir : "up_left", prio : 1},
			{dir : "left", prio : 0},
			{dir : "down_left", prio : 1},
			{dir : "down", prio : 0},
			{dir : "down_right", prio : 1}
		];
		for (i in 0...8) {
			spr.anim.registerStateAnim("walk_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return isMoving() && dir == i);
			spr.anim.registerStateAnim("idle_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return !isMoving() && dir == i);
		}
		super.init(x, z, tmxObj);

		#if !headless
		// public var invGrid : InventoryGrid;

		if ( inst == this ) ui = new PlayerUI(Main.inst.root);

		mesh.isLong = true;
		mesh.isoWidth = mesh.isoHeight = 0.1;

		#if depth_debug
		mesh.renewDebugPts();
		#end
		#end

		// Костыльный фикс ебаного бага с бампом игрока при старте уровня
		lock(30);
		// inventory.invGrid.giveItem();

		#if headless
		enableReplication = true;
		#end
	}

	/* записывает настройки  */
	public function saveSettings() {
		if ( inst == this ) {
			Settings.params.inventoryCoordRatio.x = Player.inst.ui.inventory.win.x / Main.inst.w();
			Settings.params.inventoryCoordRatio.y = Player.inst.ui.inventory.win.y / Main.inst.h();

			Settings.params.inventoryVisible = ui.inventory.win.visible;
		}
	}

	override function set_netX(v : Float) : Float {
		if ( inst != this ) {
			footX = v;
		}
		return super.set_netX(v);
	}

	override function set_netY(v : Float) : Float {
		if ( inst != this ) {
			footY = v;
		}
		return super.set_netY(v);
	}

	override function customSerialize(ctx : Serializer) {
		super.customSerialize(ctx);

		// holditem
		if ( holdItem != null ) {
			ctx.addString(Std.string(holdItem.cdbEntry));
			ctx.addInt(holdItem.amount);
		} else {
			ctx.addString("null");
			ctx.addInt(0);
		}
	}

	override function customUnserialize(ctx : Serializer) {
		if ( inst == null ) inst = this;

		super.customUnserialize(ctx);

		// holditem
		var holdItemCdb = ctx.getString();
		var holdItemAmt = ctx.getInt();

		if ( holdItemCdb != "null" ) {
			var item = Item.fromCdbEntry(Data.items.resolve(holdItemCdb).id, holdItemAmt);
			item.containerEntity = this;
			holdItem = item;
		}
	}

	override public function networkAllow(op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable) : Bool {
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
			sprFrame = {group : "null", frame : 0};
		}
		this.netX = netX;
		this.netY = netY;
		initNickname();
		syncFrames();
	}

	public function initNickname() {
		var nicknameLabel = new TextLabel(nickname, Assets.fontPixel);
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
		ui.inventory.invGrid.disableGrid();
	}

	public function enableGrids() {
		ui.inventory.invGrid.enableGrid();
	}

	override function dispose() {
		super.dispose();
		#if !headless
		if ( inst == this ) {
			saveSettings();
			inst = null;
		}
		ui.remove();
		ui = null;
		if ( nicknameMesh != null ) {
			nicknameMesh.remove();
			nicknameMesh = null;
		}
		holdItem.remove();
		holdItem = null;
		#end
	}

	// multiplayer
	function syncFrames() {
		if ( sprFrame != null ) {
			if ( spr.frame != sprFrame.frame || spr.groupName != sprFrame.group ) {
				if ( this == inst ) sprFrame = {group : spr.groupName, frame : spr.frame}; else if ( sprFrame == null ) sprFrame = {group : "null", frame : 0}
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
					var s = 0.325 * leftDist * tmod;
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
		// if (Key.isPressed(Key.E)) {
		// 	new FloatingItem(mesh.x, mesh.z, new GraviTool());
		// }
		if ( ca.isKeyboardPressed(Key.R) ) {
			if ( holdItem != null && Std.isOfType(holdItem, Blueprint) && cast(holdItem, Blueprint).ghostStructure != null ) {
				cast(holdItem, Blueprint).ghostStructure.flipX();
			}
		}
		#end
	}

	override function checkCollisions() {
		super.checkCollisions();
		if ( !isLocked() ) checkCollsAgainstAll();
	}

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
		if ( ca.isKeyboardPressed(Key.MOUSE_WHEEL_DOWN) ) cellToSelect++;
		if ( ca.isKeyboardPressed(Key.MOUSE_WHEEL_UP) ) cellToSelect--;
		if ( cellToSelect != ui.belt.selectedCellNumber ) {
			if ( cellToSelect < 1 ) cellToSelect = ui.belt.beltSlots.length;
			if ( cellToSelect > ui.belt.beltSlots.length ) cellToSelect = 1;
			ui.belt.selectCell(cellToSelect);
		}

		if ( ca.selectPressed() ) {
			var hiddenTopWindow : Void -> Bool = () -> {
				for (i in Window.ALL) {
					if ( i.win.visible ) {
						i.toggleVisible();
						return true;
					}
				}
				return false;
			};
			if ( !hiddenTopWindow() && !Game.inst.pauseCycle ) {
				Game.inst.pause();
				Game.inst.pauseCycle = true;
				new PauseMenu();
			}
		}

		if ( ca.yPressed() ) {
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
			}
		}
	}
}
