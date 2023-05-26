import h3d.Engine;
import imgui.ImGui;
import imgui.ImGuiDrawable;
import util.Util;
import util.tools.Settings;
import pass.CustomRenderer;
import util.tools.Save;
import util.Env;
import util.Repeater;
import h2d.Scene;
import dn.heaps.input.Controller;

class Boot extends hxd.App {

	public static var inst( default, null ) : Boot;

	public var sceneBehind3d : Scene;
	public var renderer : CustomRenderer;
	public var deltaTime( default, null ) : Float;

	static function main() {
		new Boot();
	}

	override function setup() {
		super.setup();
		sevents.addScene( sceneBehind3d );
	}

	override function mainLoop() {
		super.mainLoop();
		var dt = hxd.Timer.dt;
		if ( sceneBehind3d != null ) sceneBehind3d.setElapsedTime( dt );
	}

	// Engine ready
	override function init() {
		Env.init();
		Settings.init();
		Save.initFields();

		new Repeater( hxd.Timer.wantedFPS );

		sceneBehind3d = new Scene();

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

	override function render( e : Engine ) {
		// e.clear( h3d.Engine.getCurrent().backgroundColor, 1 );
		sceneBehind3d.render( e );
		s3d.render( e );
		s2d.render( e );
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
		sceneBehind3d.checkResize();
	}

	var speed = 1.0;

	override function update( dt : Float ) {
		// Manager.get().listener.syncCamera(s3d.camera);
		this.deltaTime = dt;
		var tmod = hxd.Timer.tmod * speed;
		dn.Process.updateAll( tmod );
		super.update( dt );
	}

	public function createServer() {
		sys.thread.Thread.create(() -> {
			switch Env.system {
				case Windows:
					Sys.command( "./tc.exe server.hl" );
				default:
					#if debug
					Sys.command( "hl bin/server.hl" );
					#else
					Sys.command( "./hl server.hl" );
					#end
			};
		} );
	}
}
