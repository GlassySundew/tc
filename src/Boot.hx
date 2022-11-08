import utils.Util;
import utils.tools.Settings;
import pass.CustomRenderer;
import utils.tools.Save;
import utils.Env;
import utils.Repeater;
import h2d.Scene;
import dn.heaps.input.Controller;

class Boot extends hxd.App {

	public static var inst : Boot;

	public var renderer : CustomRenderer;
	public var deltaTime( default, null ) : Float;

	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		Env.init();
		Settings.init();
		Save.initFields();

		new Repeater( hxd.Timer.wantedFPS );

		haxe.Log.trace = function ( v : Dynamic, ?infos : haxe.PosInfos ) {
			#if hx_concurrent
			var str = formatOutput( v, infos );
			Sys.println( str );
			#else
			if ( !StringTools.startsWith( infos.fileName, "hx/concurrent" ) ) {
				var str = haxe.Log.formatOutput( v, infos );
				Sys.println( str );
			}
			#end
		}

		#if !debug
		hl.UI.closeConsole();
		#end

		inst = this;
		Util.hollowScene = new Scene();

		new Main( s2d );

		onResize();
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var speed = 1.0;

	override function update( deltaTime : Float ) {
		// Manager.get().listener.syncCamera(s3d.camera);
		this.deltaTime = deltaTime;
		var tmod = hxd.Timer.tmod * speed;
		dn.Process.updateAll( tmod );
		super.update( deltaTime );
	}

	public function createServer() {
		sys.thread.Thread.create(() -> {
			switch Env.system {
				case Windows:
					Sys.command( ".\tc.exe server.hl" );
				default:
					#if debug
					Sys.command( "hl bin/server.hl" );
					#else
					Sys.command( "./tc server.hl" );
					#end
			};
		} );
	}
}
