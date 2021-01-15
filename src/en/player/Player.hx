package en.player;

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

class Player extends Entity implements NetworkSerializable {
	@:s public var uid : Int;
	@:s public var xSer(default, set) : Float;
	@:s public var ySer(default, set) : Float;

	function set_xSer(v : Float) {
		return this.footX = v;
	}

	function set_ySer(v : Float) {
		return this.footY = v;
	}

	public static var inst : Player;

	public var ui : PlayerUI;

	public var holdItem(default, set) : en.Item;

	inline function set_holdItem(v : en.Item) {
		if ( v == null ) {
			ui.inventory.invGrid.disableGrid();
		}
		if ( v != null ) {
			// inventory.invGrid.enableGrid();
		}
		return holdItem = v;
	}

	var ca : dn.heaps.Controller.ControllerAccess;

	public function networkAllow(op : hxbit.NetworkSerializable.Operation, propId : Int, clientSer : hxbit.NetworkSerializable) : Bool {
		return clientSer == this;
	}

	public function new(x : Float, z : Float, ?tmxObj : TmxObject, ?uid : Int) {
		this.uid = uid;
		spr = new HSprite(Assets.player, entParent);
		#if !headless
		ca = Main.inst.controller.createAccess("player");
		#end

		var direcs = [
			{dir: "right", prio: 0},
			{dir: "up_right", prio: 1},
			{dir: "up", prio: 0},
			{dir: "up_left", prio: 1},
			{dir: "left", prio: 0},
			{dir: "down_left", prio: 1},
			{dir: "down", prio: 0},
			{dir: "down_right", prio: 1}
		];
		for (i in 0...8) {
			spr.anim.registerStateAnim("walk_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return isMoving() && dir == i);
			spr.anim.registerStateAnim("idle_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return !isMoving() && dir == i);
		}
		super(x, z, tmxObj);

		inst = this;

		#if !headless
		ui = new PlayerUI(game.root);

		mesh.isLong = true;
		mesh.isoWidth = mesh.isoHeight = 0;

		mesh.renewDebugPts();
		#end

		// Костыльный фикс ебаного бага с бампом игрока при старте уровня
		lock(30);
		// inventory.invGrid.giveItem();
		enableReplication = true;
	}

	public function alive() {
		trace("aliving");

		init();
		if ( uid == GameClient.inst.uid ) {
			GameClient.inst.player = this;
			GameClient.inst.host.self.ownerObject = this;
		}
		enableReplication = true;
		this.footX = xSer;
		this.footY = ySer;
	}

	public function disableGrids() {
		ui.inventory.invGrid.disableGrid();
	}

	public function enableGrids() {
		ui.inventory.invGrid.enableGrid();
	}

	override function dispose() {
		super.dispose();
		// inst = null;
		ui.remove();
		ui = null;
	}

	override public function update() {
		super.update();

		#if !headless
		var leftDist = M.dist(0, 0, ca.lxValue(), ca.lyValue());
		var leftPushed = leftDist >= 0.3;
		var leftAng = Math.atan2(ca.lyValue(), ca.lxValue());
		if ( !isLocked() ) {
			if ( leftPushed ) {
				var s = 0.325 * leftDist * tmod;
				dx += Math.cos(leftAng) * s;
				dy += Math.sin(leftAng) * s;

				if ( ca.lxValue() < -0.3 && M.fabs(ca.lyValue()) < 0.6 ) dir = 4; else if ( ca.lyValue() < -0.3 && M.fabs(ca.lxValue()) < 0.6 ) dir = 6; else
					if ( ca.lxValue() > 0.3
					&& M.fabs(ca.lyValue()) < 0.6 ) dir = 0; else if ( ca.lyValue() > 0.3 && M.fabs(ca.lxValue()) < 0.6 ) dir = 2;

				if ( ca.lxValue() > 0.3 && ca.lyValue() > 0.3 ) dir = 1; else if ( ca.lxValue() < -0.3 && ca.lyValue() > 0.3 ) dir = 3; else
					if ( ca.lxValue() < -0.3
					&& ca.lyValue() < -0.3 ) dir = 5; else if ( ca.lxValue() > 0.3 && ca.lyValue() < -0.3 ) dir = 7;
			} else {
				dx *= Math.pow(0.6, tmod);
				dy *= Math.pow(0.6, tmod);
			}
		}
		#end
	}

	override function postUpdate() {
		super.postUpdate();
		if ( this == inst && !isLocked() && ui != null ) checkBeltInputs();
		// if (Key.isPressed(Key.E)) {
		// 	new FloatingItem(mesh.x, mesh.z, new GraviTool());
		// }
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

		if ( Key.isPressed(Key.NUMBER_1) ) ui.inventory.belt.selectCell(1);
		if ( Key.isPressed(Key.NUMBER_2) ) ui.inventory.belt.selectCell(2);
		if ( Key.isPressed(Key.NUMBER_3) ) ui.inventory.belt.selectCell(3);
		if ( Key.isPressed(Key.NUMBER_4) ) ui.inventory.belt.selectCell(4);
		if ( Key.isPressed(Key.NUMBER_5) ) ui.inventory.belt.selectCell(5);

		if ( Key.isPressed(Key.Q) ) {
			if ( holdItem != null ) {
				if ( holdItem.isInSlot() ) ui.inventory.invGrid.findItemSlot(holdItem).item = null;
				holdItem = dropItem(holdItem, this.angToPxFree(level.cursX, level.cursY), 2.3);
			}
		}
	}
}
