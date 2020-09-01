package en.player;

import net.Connect;
import hxd.Window;
import ui.player.PlayerUI;
import ui.player.Inventory;
import en.objs.IsoTileSpr;
import hxd.Key;
import en.items.GraviTool;
import format.tmx.Data.TmxObject;
import differ.Collision;

class Player extends Entity {
	public static var inst:Player;

	public var ui:PlayerUI;
	public var inventory(get, never):Inventory;

	inline function get_inventory()
		return ui.inventory;

	public var holdItem(default, set):Item;

	inline function set_holdItem(v:Item) {
		if (v == null) {
			inventory.invGrid.disableGrid();
		}
		if (v != null) {
			// inventory.invGrid.enableGrid();
		}
		return holdItem = v;
	}

	var ca:dn.heaps.Controller.ControllerAccess;

	public function new(x:Float, z:Float, ?tmxObj:TmxObject) {
		spr = new HSprite(Assets.player);

		ca = Main.inst.controller.createAccess("player");

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
			spr.anim.registerStateAnim("walk_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16) * tmod, function() return isMoving() && dir == i);
			spr.anim.registerStateAnim("idle_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16) * tmod, function() return !isMoving() && dir == i);
		}

		super(x, z, tmxObj);
		mesh.isLong = true;
		mesh.isoWidth = mesh.isoHeight = 0;

		mesh.renewDebugPts();

		if (inst == null) {
			ui = new PlayerUI(game.root);
			inst = this;
		}
	}

	override function dispose() {
		super.dispose();
		inst = null;
		ui.remove();
		ui = null;
	}

	override public function update() {
		super.update();

		var leftDist = M.dist(0, 0, ca.lxValue(), ca.lyValue());
		var leftPushed = leftDist >= 0.3;
		var leftAng = Math.atan2(ca.lyValue(), ca.lxValue());
		if (!isLocked()) {
			if (leftPushed) {
				var s = 0.0075 * leftDist * tmod;
				dx += Math.cos(leftAng) * s;
				dy += Math.sin(leftAng) * s;

				if (ca.lxValue() < -0.3 && M.fabs(ca.lyValue()) < 0.6)
					dir = 4;
				else if (ca.lyValue() < -0.3 && M.fabs(ca.lxValue()) < 0.6)
					dir = 6;
				else if (ca.lxValue() > 0.3 && M.fabs(ca.lyValue()) < 0.6)
					dir = 0;
				else if (ca.lyValue() > 0.3 && M.fabs(ca.lxValue()) < 0.6)
					dir = 2;

				if (ca.lxValue() > 0.3 && ca.lyValue() > 0.3)
					dir = 1;
				else if (ca.lxValue() < -0.3 && ca.lyValue() > 0.3)
					dir = 3;
				else if (ca.lxValue() < -0.3 && ca.lyValue() < -0.3)
					dir = 5;
				else if (ca.lxValue() > 0.3 && ca.lyValue() < -0.3)
					dir = 7;
			} else {
				dx *= Math.pow(0.6, tmod);
				dy *= Math.pow(0.6, tmod);
			}
			sendPosToServer();
		}
	}

	public function sendPosToServer() {
		if (Connect.inst != null && Connect.inst.room != null)
			Connect.inst.room.send("setPos", {x: footX, y: footY});
	}

	override function postUpdate() {
		super.postUpdate();
		if (this == inst && !isLocked() && ui != null)
			checkBeltInputs();
		// if (Key.isPressed(Key.E)) {
		// 	new FloatingItem(mesh.x, mesh.z, new GraviTool());
		// }

		if (holdItem != null && holdItem.isInCursor()) {
			holdItem.x = Boot.inst.s2d.mouseX + 15 * holdItem.scaleX;
			holdItem.y = Boot.inst.s2d.mouseY + 15 * holdItem.scaleX;
		}
	}

	override function checkCollisions() {
		if (!isLocked())
			checkCollsAgainstAll();
		super.checkCollisions();
	}

	function checkBeltInputs() {
		if (ca.isPressed(LT)) {
			inventory.toggleVisible();
		}

		if (Key.isPressed(Key.NUMBER_1))
			inventory.belt.selectCell(1);

		if (Key.isPressed(Key.NUMBER_2))
			inventory.belt.selectCell(2);

		if (Key.isPressed(Key.NUMBER_3))
			inventory.belt.selectCell(3);

		if (Key.isPressed(Key.NUMBER_4))
			inventory.belt.selectCell(4);

		if (Key.isPressed(Key.Q)) {
			if (holdItem != null)
				holdItem = dropItem(holdItem, this.angToPxFree(level.cursX, level.cursY), 0.05);
		}
	}
}
