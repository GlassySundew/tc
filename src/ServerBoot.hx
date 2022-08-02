/**
	entrypoint for headless standalone server executable
**/

import hxd.Timer;
import net.Server;

/** server-side **/
class ServerBoot {

	public static var inst : ServerBoot;

	public var engine( default, null ) : h3d.Engine;

	public static var server : Server;

	static public function main() : Void {
		inst = new ServerBoot();
	}

	@:dox( show )
	function loadAssets( onLoaded : Void -> Void ) {
		onLoaded();
	}

	var speed = 1.0;
	final thousandslashsixty = 1000 / 60;

	function mainLoop() {
		Sys.sleep( ( thousandslashsixty - Timer.dt ) / 1000 );
		hxd.Timer.update();

		var dt = hxd.Timer.dt;

		var tmod = hxd.Timer.tmod * speed;
		dn.Process.updateAll( tmod );
	}

	function update( dt : Float ) {}

	public function new() {

		haxe.Log.trace = function ( v : Dynamic, ?infos : haxe.PosInfos ) {
			var str = haxe.Log.formatOutput( v, infos );
			Sys.println( "[SERVER] " + str );
		}

		hxd.System.start( function () {
			loadAssets( function () {
				hxd.Timer.skip();
				mainLoop();
				hxd.System.setLoop( mainLoop );

				server = new Server();

				// зачем надо хз
				// @:privateAccess new h3d.Engine();
				// engine.init();

				// hollowScene = new Scene();
			} );
		} );
	}
}
