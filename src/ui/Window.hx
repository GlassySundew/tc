package ui;

import utils.Util;
import utils.Const;
import game.client.GameClient;
import hxbit.Serializable;
import ch2.ui.EventInteractive;
import h2d.Flow;
import h2d.Layers;
import h2d.Object;
import ui.domkit.WindowComp.WindowCompI;

class Window extends dn.Process {

	public static var ALL : Array<Window> = [];

	var windowComp : WindowCompI;

	public var win : Object;

	public var isVisible( get, never ) : Bool;

	inline function get_isVisible() : Bool return win.visible;

	/**backdround sprite**/
	var backgroundInter : EventInteractive;

	/**
		@param parent is usually supposed to be Player.inst.pui
	**/
	public function new( ?parent : Object ) {
		super( GameClient.inst );

		beforeLoad( parent );
		initLoad();
		afterLoad();
	}

	public function beforeLoad( ?parent : Object ) {
		ALL.push( this );
		win = new h2d.Object( parent );
	}

	public function initLoad() {}

	public function afterLoad() {
		updateBackgroundInteractive();
	}

	public function updateBackgroundInteractive() {
		if ( win != null && windowComp != null && windowComp.window != null && win.parent != null ) {
			if ( backgroundInter != null ) backgroundInter.remove();

			backgroundInter = new EventInteractive( windowComp.window.getSize().width, windowComp.window.getSize().height );
			win.addChildAt( backgroundInter, 0 );
			backgroundInter.cursor = hxd.Cursor.Default;
			backgroundInter.onPush = function ( e ) {
				bringOnTopOfALL();
			};
		}
	}

	public function recenter() {
		if ( win != null ) {
			var size = win.getSize();
			win.x = Std.int( ( Util.wScaled - size.width ) / 2 );
			win.y = Std.int( ( Util.hScaled - size.height ) / 2 );
		}
	}

	function clampInScreen() {
		if ( win != null && windowComp != null ) {
			win.x = hxd.Math.clamp( win.x, 0, Util.wScaled - windowComp.window.innerWidth );
			win.y = hxd.Math.clamp( win.y, 0, Util.hScaled - windowComp.window.innerHeight );
		}
	}

	public function bringOnTopOfALL() {
		if ( win.parent != null ) try {
			Std.downcast( win.parent, Layers ).add( win, Const.DP_UI );
		} catch( e ) {
			win.parent.addChild( win );
		}
		ALL.remove( this );
		ALL.unshift( this );
	}

	public function clearWindow() {
		win.removeChildren();
	}

	override function update() {
		super.update();
	}

	public inline function add( e : h2d.Flow ) {
		win.addChild( e );
		onResize();
	}

	override function onResize() {
		super.onResize();
		if ( win != null ) clampInScreen();
	}

	function onClose() {}

	override function onDispose() {
		super.onDispose();
		win.remove();
		ALL.remove( this );
	}

	public function toggleVisible() {
		win.visible = !win.visible;
		clampInScreen();
		bringOnTopOfALL();
	}

	public function close() {
		if ( !destroyed ) {
			destroy();
			onClose();
		}
	}
}
