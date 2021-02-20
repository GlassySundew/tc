package en.player;

import en.items.Blueprint;
import ui.InventoryGrid.CellGrid;
import h2d.Tile;
import h3d.mat.Texture;
import ch3.scene.TileSprite;
import h3d.scene.Mesh;
import ui.TextLabel;
import h2d.Text;
import hxd.System;
import hxbit.NetworkSerializable;
import dn.Process;
import h2d.Scene;
import hxd.Window;
import ui.player.PlayerUI;
import ui.player.Inventory;
import en.objs.IsoTileSpr;
import hxd.Key;
import en.items.GraviTool;
import format.tmx.Data.TmxObject;
import differ.Collision;

class Player extends Entity {
	public static var inst : Player;

	var nicknameMesh : TileSprite;

	@:s public var sprFrame : {group : String, frame : Int};

	@:s public var nickname : String;
	public var ui : PlayerUI;
	public var invGrid : CellGrid;

	var ca : dn.heaps.Controller.ControllerAccess;

	public var holdItem(default, set) : en.Item;

	inline function set_holdItem(v : en.Item) {
		if ( holdItem != null ) holdItem.onPlayerRemove.dispatch();
		if ( v == null ) {
			for (i in Inventory.ALL) i.invGrid.disableGrid();
		}
		if ( v != null ) {
			v.onPlayerHold.dispatch();
			Boot.inst.s2d.addChild(v);
			v.scaleX = v.scaleY = 2;
			// inventory.invGrid.enableGrid();
		}
		return holdItem = v;
	}

	public function new(x : Float, z : Float, ?tmxObj : TmxObject, ?uid : Int, ?nickname : String) {
		this.nickname = nickname;
		this.uid = uid;
		inst = this;

		super(x, z, tmxObj);
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

	override public function networkAllow(op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable) : Bool {
		// trace(clientSer == this && this == inst);
		// var player = cast(clientSer, Player);
		return clientSer == this;
	}

	override function init(?x : Float, ?z : Float, ?tmxObj : TmxObject) {
		spr = new HSprite(Assets.player, entParent);
		#if !headless
		ca = Main.inst.controller.createAccess("player");
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

		ui = new PlayerUI(Main.inst.root);

		mesh.isLong = true;
		mesh.isoWidth = mesh.isoHeight = 0;

		#if dispDepthBoxes
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
			sprFrame = {group : "zhopa", frame : 0};
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
		inst = null;
		ui.remove();
		ui = null;
		if ( nicknameMesh != null ) {
			nicknameMesh.remove();
			nicknameMesh = null;
		}
		#end
	}

	function syncFrames() {
		if ( sprFrame != null ) {
			if ( spr.frame != sprFrame.frame || spr.groupName != sprFrame.group ) {
				if ( this == inst ) sprFrame = {group : spr.groupName, frame : spr.frame}; else if ( sprFrame == null ) sprFrame = {group : "zhopa", frame : 0}
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
		if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();
		// if (Key.isPressed(Key.E)) {
		// 	new FloatingItem(mesh.x, mesh.z, new GraviTool());
		// }
		if ( ca.isKeyboardPressed(Key.R) ) {
			if ( holdItem != null && Std.isOfType(holdItem, Blueprint) && cast(holdItem, Blueprint).ghostStructure != null ) {
				cast(holdItem, Blueprint).ghostStructure.flipX();
			}
		}
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

		if ( ca.isKeyboardPressed(Key.MOUSE_WHEEL_DOWN) ) {}
		if ( ca.isKeyboardPressed(Key.MOUSE_WHEEL_UP) ) {}

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
