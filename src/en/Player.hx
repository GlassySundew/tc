package en;

import differ.Collision;
import hxd.Key;
import h3d.Vector;
import h3d.shader.NormalMap;
import h3d.prim.Cube;
import h2d.Tile;
import h2d.Bitmap;
import h3d.prim.PlanePrim;
import h3d.mat.Texture;
import hxd.Res;
import h3d.scene.Mesh;
import hxd.Key in K;
import h2d.Anim;

class Player extends Entity {
	var ca:dn.heaps.Controller.ControllerAccess;

	public function new(x:Float, z:Float) {
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

		super(x, z);
		sprOffX = -.5;
		sprOffY = 0;

		// sprOffCollY = -.45;
		// obj.material.mainPass.addShader(new NormalMap(tex));
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

		// trace(xr, yr, cx, cy, ((footX / Const.GRID_WIDTH) ) % 1, ((footX / Const.GRID_WIDTH) ) - ((footX / Const.GRID_WIDTH) ) % 1 );
	}

	override function checkCollisions() {
		super.checkCollisions();

		for (ent in Entity.ALL) {
			var collideInfo = Collision.shapeWithShape(collisions[0], ent.collisions[0]);
			if (collideInfo != null) {
				collisions[0].x += collideInfo.separationX;
				collisions[0].y += collideInfo.separationY;
			}
		}
		footX = collisions[0].x;
		footY = collisions[0].y;

	}
}
