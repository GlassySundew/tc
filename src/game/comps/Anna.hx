package game.comps;

import h2d.Tile;
import h2d.Bitmap;
import h3d.prim.PlanePrim;
import h3d.mat.Texture;
import hxd.Res;
import h3d.shader.BaseMesh;
import h3d.scene.Mesh;
import engine.HXP;
import engine.*;
import hxd.Key in K;
import h2d.Anim;

class Anna extends Character {
	private var tex:Texture;
	private var prim:PlanePrim;

	public var obj:Mesh;

	private var mesh:S3DComponent;

	private var anim:Anim;
	private var idle:Array<Tile>;

	private var rotAngle:Float = -0.1;
	private var x:Float;
	private var y:Float;

	public function new(scene:TestScene, name:String, x:Float, y:Float) {
		super(scene, name);
		this.x = x;
		this.y = y;
		obj.x = x;
		obj.y = y;
		// HXP.wrap(this, "Anna");
	}

	override public function setup() {
		super.setup();

		var bmp = new Bitmap(hxd.Res.tiled.separated.anna_png.toTile());
		tex = new Texture(Std.int(bmp.tile.width), Std.int(bmp.tile.height), [Target]);
		bmp.drawTo(tex);
		tex.filter = Nearest;

		prim = new PlanePrim(tex.width, tex.height, -tex.width / 2, -tex.height / 2);
		obj = new Mesh(prim, h3d.mat.Material.create(tex), scene.s3d);
		obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		obj.material.blendMode = Alpha;

		obj.rotate(rotAngle, 0, 0);
		obj.z = (obj.material.texture.height - 11) * Math.cos(90 * Math.PI / 180 + rotAngle);

		idle = new Array<Tile>();

		for (i in 1...9)
			idle.push(Res.tiled.anna_move.get("idle_front_" + i));
		anim = new Anim(idle, 1, HXP.engine.s2d);
		anim.visible = false;
		owner.add(mesh = new S3DComponent(obj));
	}

	override public function update(delta:Float) {
		super.update(delta);

		tex.clear(0, 0);
		var test = new Bitmap(anim.getFrame());
		test.drawTo(tex);

		if (scene.key.up) {
			obj.y--;
		}
		if (scene.key.left)
			obj.x--;
		if (scene.key.down)
			obj.y++;
		if (scene.key.right)
			obj.x++;
		if (scene.key.action) {}
	}
}
