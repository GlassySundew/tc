package game.comps;

import engine.Music;
import h3d.Vector;
import hxd.res.Model;
import engine.shaders.PlayStationShader;
import h3d.anim.Animation;
import game.data.ConfigJson;
import hxd.Timer;
import hxd.Res;
import h3d.shader.BaseMesh;
import engine.HXP;
import h3d.scene.Mesh;
import h3d.scene.Object;
import engine.S3DComponent;
import engine.HComp;
import engine.utils.ModelUtil;
import engine.*;

class Character extends HComp {
	// private var anim:String;
	var game:Main;
	var scene:TestScene;

	public function new(scene:TestScene, name:String) {
		super();
		this.scene = scene;
		game = Main.inst;
		HXP.wrap(this, name);
	}

	override public function setup() {}

	override public function update(delta:Float) {
		//super.update(delta);

		// mesh.obj.rotate(0, 0, Timer.deltaT * .5);
	}
}
