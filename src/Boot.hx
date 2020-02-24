import hxd.inspect.Inspector;

class Boot extends hxd.App {
	public static var inst:Boot;
	public var i:Inspector;

	// Boot
	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		inst = this;
		new Main(s2d);
		
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

		var tmod = hxd.Timer.tmod * speed;
		#if debug
		tmod *= hxd.Key.isDown(hxd.Key.NUMPAD_ADD) ? 5 : 1;
		#end
		dn.heaps.Controller.beforeUpdate();
		dn.Process.updateAll(tmod);
	}
}
