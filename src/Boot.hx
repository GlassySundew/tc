import h2d.Scene;
import tools.Save;

class Boot extends hxd.App {
	public static var inst : Boot;

	public var customScenes : Array<Scene> = [];
	public var renderer : CustomRenderer;

	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		Env.init();
		Settings.init();
		Save.initFields();

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

		sys.thread.Thread.create(() -> {
			switch Env.system {
				case Windows:
					Sys.command(".\tc.exe server.hl");
				default:
					#if debug
					Sys.command("hl bin/server.hl");
					#else
					Sys.command("./tc server.hl");
					#end
			};
		});

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