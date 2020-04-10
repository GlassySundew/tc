import hxd.snd.Manager;
import hxd.inspect.Inspector;

class Boot extends hxd.App {
	public static var inst:Boot;

	public var i:Inspector;

	public var renderer:CustomRenderer;

	// Boot
	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		inst = this;
		new Main(s2d);
		renderer = new CustomRenderer();
		s3d.renderer = renderer;
		renderer.depthColorMap = hxd.Res.gradients.test.toTexture();
		renderer.enableFXAA = false;
		renderer.enableSao = false;
		
		s3d.lightSystem.ambientLight.set(0.5, 0.5, 0.5);
		onResize();
		#if (castle && hl && debug)
		i = new hxd.inspect.Inspector(s3d);
		#end
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}
	
	var speed = 1.0;

	override function update(deltaTime:Float) {
		super.update(deltaTime);
		// Bullet time
		#if debug
		if (hxd.Key.isPressed(hxd.Key.NUMPAD_SUB))
			speed = speed >= 1 ? 0.33 : 1;
		#end
		// Manager.get().listener.syncCamera(s3d.camera);
		var tmod = hxd.Timer.tmod * speed;
		#if debug
		tmod *= hxd.Key.isDown(hxd.Key.NUMPAD_ADD) ? 5 : 1;
		#end
		dn.heaps.Controller.beforeUpdate();
		dn.Process.updateAll(tmod);
	}
}
