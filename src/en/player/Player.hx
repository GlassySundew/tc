package en.player;

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
		return holdItem = v;
	}

	public var cursorItem(default, set):Item;

	inline function set_cursorItem(v:Item) {
		if (v == null) {
			inventory.invGrid.disableGrid();
		}
		if (v != null) {
			holdItem = v;
			inventory.invGrid.enableGrid();
		}
		return cursorItem = v;
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
		inst = this;
		mesh.isLong = true;
		mesh.isoWidth = mesh.isoHeight = 0;

		mesh.renewDebugPts();

		ui = new PlayerUI(game.root);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
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
		}
	}

	override function postUpdate() {
		super.postUpdate();
		checkBeltInputs();
		// trace("player");
		// if (Key.isPressed(Key.E)) {
		// 	new FloatingItem(mesh.x, mesh.z, new GraviTool());
		// }

		if (cursorItem != null) {
			// cursorItem.x = Window.getInstance().mouseX /Const.SCALE;
			// cursorItem.y = Window.getInstance().mouseY /Const.SCALE;

			cursorItem.x = Boot.inst.s2d.mouseX + 10 * cursorItem.scaleX;
			cursorItem.y = Boot.inst.s2d.mouseY + 10 * cursorItem.scaleX;
		}
	}

	override function checkCollisions() {
		super.checkCollisions();
		checkCollsAgainstAll();
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
	}
}
