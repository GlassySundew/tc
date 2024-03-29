import h3d.Engine;
import hxd.Window;
import h2d.Scene;
import hxd.inspect.Inspector;

class Boot extends hxd.App {
	public static var inst : Boot;

	public var inspector : Inspector;

	public var renderer : CustomRenderer;

	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		#if !debug
		hl.UI.closeConsole();
		#end

		inst = this;
		entParent = new Scene();

		new Main(s2d);

		// s2d.scaleMode = AutoZoom(640, 360, true);
		// s2d.scaleMode = LetterBox(640, 360, true, Center, Center);

		s3d.lightSystem.ambientLight.set(1, 1, 1);
		onResize();
		// Window.
		#if( castle && hl && debug )
		inspector = new hxd.inspect.Inspector(s3d);
		#end
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var speed = 1.0;

	override function update(deltaTime : Float) {

		// Bullet time
		#if debug
		if ( hxd.Key.isPressed(hxd.Key.NUMPAD_SUB) ) speed = speed >= 1 ? 0.33 : 1;
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
