import hx.concurrent.executor.Executor;
import mapgen.MapGen;
import h2d.Scene;

class Boot extends hxd.App {
	public static var inst : Boot;

	public var customScenes : Array<Scene> = [];
	public var renderer : CustomRenderer;

	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		haxe.Log.trace = function ( v : Dynamic, ?infos : haxe.PosInfos ) {
			#if hx_concurrent
			var str = formatOutput(v, infos);
			Sys.println(str);
			#else
			if ( !StringTools.startsWith(infos.fileName, "hx/concurrent") ) {
				var str = haxe.Log.formatOutput(v, infos);
				Sys.println(str);
			}
			#end
		}

		#if !debug
		hl.UI.closeConsole();
		#end

		inst = this;
		entParent = new Scene();

		new Main(s2d);

		// s3d.lightSystem.ambientLight.set(1, 1, 1);
		onResize();
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var speed = 1.0;

	override function update( deltaTime : Float ) {
		// Manager.get().listener.syncCamera(s3d.camera);
		var tmod = hxd.Timer.tmod * speed;
		dn.heaps.Controller.beforeUpdate();
		dn.Process.updateAll(tmod);
		super.update(deltaTime);
	}
}
	// @formatter:off