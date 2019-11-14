package en;

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

		// tilesHero.defineAnim('idle_down_right', "0(1/0.25)");
		// for (i in 0...(direc.length - 1))
		// 	spr.anim.registerStateAnim(action[0] + direc[i], 0, 0.2);
		// for (i in 0...(direc.length - 1))
		// 	spr.anim.registerStateAnim(action[1] + direc[i], 1, 0.2, function() return isMoving());

		spr.anim.registerStateAnim("walk_right", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 0);
		spr.anim.registerStateAnim("walk_up_right", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 1);
		spr.anim.registerStateAnim("walk_up", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 2);
		spr.anim.registerStateAnim("walk_up_left", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 3);
		spr.anim.registerStateAnim("walk_left", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 4);
		spr.anim.registerStateAnim("walk_down_left", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 5);
		spr.anim.registerStateAnim("walk_down", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 6);
		spr.anim.registerStateAnim("walk_down_right", 0, (1 / 60 / 0.16), function() return isMoving() && dir == 7);

		spr.anim.registerStateAnim("idle_right", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 0);
		spr.anim.registerStateAnim("idle_up_right", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 1);
		spr.anim.registerStateAnim("idle_up", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 2);
		spr.anim.registerStateAnim("idle_up_left", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 3);
		spr.anim.registerStateAnim("idle_left", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 4);
		spr.anim.registerStateAnim("idle_down_left", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 5);
		spr.anim.registerStateAnim("idle_down", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 6);
		spr.anim.registerStateAnim("idle_down_right", 0, (1 / 60 / 0.16), function() return !isMoving() && dir == 7);

		super(x - .5, z);
		// spr.anim.playAndLoop("idle_down");
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
				var s = 0.006 * leftDist * tmod;
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
			// trace(spr.anim.getPlayRatio());
		}

		// new Bitmap(spr.tile, Boot.inst.s2d).drawTo(tex);

		// 	var motion = new Vector();
		// 	tex.clear(0, 0);
		// 	if (level.key.up) {
		// 		if (level.key.left) {
		// 			play("walk_up_left");
		// 			motion.y += .5;
		// 		} else if (level.key.right) {
		// 			play("walk_up_right");
		// 			motion.y += .5;
		// 		} else {
		// 			play("walk_up");
		// 			motion.y++;
		// 		}
		// 	} else if (level.key.down) {
		// 		if (level.key.left) {
		// 			play("walk_down_left");
		// 			motion.y -= .5;
		// 		} else if (level.key.right) {
		// 			play("walk_down_right");
		// 			motion.y -= .5;
		// 		} else {
		// 			play("walk_down");
		// 			motion.y--;
		// 		}
		// 	}
		// 	if (level.key.left) {
		// 		if (!(level.key.down || level.key.up))
		// 			play("walk_left");
		// 		motion.x--;
		// 	} else if (level.key.right) {
		// 		if (!(level.key.down || level.key.up))
		// 			play("walk_right");
		// 		motion.x++;
		// 	}
		// 	if (!(level.key.right || level.key.left || level.key.down || level.key.up)) {
		// 		if (level.key.up_isReleased || level.key.down_isReleased || level.key.left_isReleased || level.key.right_isReleased)
		// 			pos = new Vector(Math.round(pos.x), 0, Math.round(pos.z));
		// 		if (level.key.up_isReleased) {
		// 			if (level.key.left)
		// 				play("idle_up_left");
		// 			else if (level.key.right_isReleased)
		// 				play("idle_up_right");
		// 			play("idle_up");
		// 		} else if (level.key.down_isReleased) {
		// 			if (level.key.left_isReleased)
		// 				play("idle_down_left");
		// 			else if (level.key.right_isReleased)
		// 				play("idle_down_right");
		// 			play("idle_down");
		// 		} else if (level.key.left_isReleased)
		// 			play("idle_left");
		// 		else if (level.key.right_isReleased)
		// 			play("idle_right");
		// 	}
		// 	if (level.key.action) {}
		// 	motion.normalize();
		// 	// motion.scale3(delta * 50);
		// 	pos.x += motion.x;
		// 	pos.z += motion.y;
		// 	var smoothPos = new Vector();
		// 	smoothPos.lerp(new Vector(obj.x, 0, obj.z), pos, .2);
		// 	move(smoothPos.x - obj.x, smoothPos.z - obj.z);
		// 	if (!level.key.action) {
		// 	}
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
