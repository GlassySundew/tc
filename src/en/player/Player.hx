package en.player;

import en.objs.IsoTileSpr;
import hxd.Key;
import en.items.GraviTool;
import format.tmx.Data.TmxObject;
import differ.Collision;

class Player extends Entity {
	public static var inst:Player;

	public var inventory:Inventory;

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
			v.spr.scaleX = v.spr.scaleY = 2;
		}
		return cursorItem = v;
	}

	var ca:dn.heaps.Controller.ControllerAccess;

	public function new(x:Float, z:Float, ?tmxObj:TmxObject) {
		spr = new HSprite(Assets.tiles);

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
			spr.anim.registerStateAnim("walk_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return isMoving() && dir == i);
			spr.anim.registerStateAnim("idle_" + direcs[i].dir, direcs[i].prio, (1 / 60 / 0.16), function() return !isMoving() && dir == i);
		}

		super(x, z, tmxObj);
		// var mesh = Std.downcast(mesh,IsoTileSpr);
		inst = this;
		mesh.isLong = true;
		mesh.verts = {
			right: {x: 0, z: -0},
			down: {x: -0, z: -0},
			left: {x: -0, z: 0},
			up: {x: 0, z: 0}
		};
		mesh.renewDebugPts();
		// sprOffY -= 1;
		// mesh.material.texture.depthBuffer = new DepthBuffer(7, 13);
		inventory = new Inventory();
		// tempI = new FloatingItem(footX, footY - 30, new en.items.Ore(0, 0, Iron));
		// new FloatingItem(footX + 22, footY - 20, new en.items.GraviTool());
		// tempI.footX = footX;
		// tempI.footY = footY - 30;
		// tempP = new FloatingItem
		// sprOffCollY = -.45;
		// obj.material.mainPass.addShader(new NormalMap(tex));
		bottomAlpha = -1;
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	override public function update() {
		super.update();
		// temp ? {mesh.material.mainPass.depth(false, Less); temp = false;} : {
		// 	mesh.material.mainPass.depth(true, LessEqual);
		// 	temp = true;
		// };
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

		if (cursorItem != null) {
			cursorItem.x = Boot.inst.s2d.mouseX + 25;
			cursorItem.y = Boot.inst.s2d.mouseY + 25;
		}
	}

	override function checkCollisions() {
		super.checkCollisions();
		checkBeltInputs();
		for (ent in Entity.ALL) {
			if (ent.collisions[0] != null) {
				var collideInfo = Collision.shapeWithShape(collisions[0], ent.collisions[0]);
				if (collideInfo != null) {
					collisions[0].x += (collideInfo.separationX);
					collisions[0].y += (collideInfo.separationY);
				}
			}
		}
		for (poly in Level.inst.walkable) {
			var collideInfo = Collision.shapeWithShape(collisions[0], poly);
			if (collideInfo != null) {
				collisions[0].x += (collideInfo.separationX);
				collisions[0].y += (collideInfo.separationY);
			}
		}

		footX = (collisions[0].x);
		footY = (collisions[0].y);
	}

	function checkBeltInputs() {
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
