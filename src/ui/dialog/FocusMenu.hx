package ui.dialog;

import dn.Process;
import h2d.Flow;
import h2d.Object;
import h2d.Tile;

class FocusMenu extends Process {

	static var menus : Array<FocusMenu> = [];

	var overlayFlow : Flow;

	var ca : ControllerAccess<ControllerAction>;

	public var h2dObject : Object;

	var onSceneAddedObject : OnSceneAddedObject;
	var contentFlow : Flow;
	var centrized = false;
	var contentTopPadding( get, never ) : Int;

	function get_contentTopPadding() : Int
		return 0;

	// return -Std.int( Util.hScaled / 4 );

	public function new( ?parent : Object, ?parentProcess : Process ) {
		super( parentProcess );

		menus.push( this );

		h2dObject = new Object();

		if ( parent == null )
			Main.inst.root.add( h2dObject, Const.DP_UI );
		else
			parent.addChild( h2dObject );

		overlayFlow = new Flow( h2dObject );
		overlayFlow.backgroundTile = Tile.fromColor( 0x000000, 1, 1, 0.75 );
		overlayFlow.enableInteractive = true;
		overlayFlow.interactive.onClick = backgroundOnClick;

		contentFlow = new Flow( h2dObject );
		contentFlow.verticalSpacing = 5;
		contentFlow.verticalAlign = Middle;

		ca = Main.inst.controller.createAccess();
		ca.takeExclusivity();
		ca.lock( 0.1 );

		onSceneAddedObject = new OnSceneAddedObject( h2dObject );

		onResize();
	}

	function centrizeContent( ?paddingLeft = 80 ) {
		centrized = true;

		contentFlow.paddingLeft = paddingLeft;
		contentFlow.layout = Vertical;
	}

	override function update() {
		super.update();

		if ( ca.isPressed( Escape ) ) {
			destroy();
		}
	}

	function backgroundOnClick( e ) {
		destroy();
	}

	function addOnSceneAddedCb( cb : Void -> Void ) {
		if ( h2dObject.getScene() != null ) {
			cb();
		} else {
			onSceneAddedObject.onAddedToSceneEvent.add( cb );
		}
	}

	override function onDispose() {
		super.onDispose();

		ca.releaseExclusivity();
		ca.dispose();

		menus.remove( this );

		if ( menus.length > 0 ) {
			menus[menus.length - 1].ca.takeExclusivity();
			menus[menus.length - 1].onFocus();
		}

		h2dObject.remove();
	}

	function onFocus() {}

	override function onResize() {
		super.onResize();

		overlayFlow.minHeight = hScaled;
		overlayFlow.minWidth = wScaled;

		if ( centrized ) {
			contentFlow.minHeight = contentFlow.maxHeight = Std.int( Util.hScaled );
			contentFlow.minWidth = contentFlow.maxWidth = Std.int( Util.wScaled );
			contentFlow.paddingTop = contentTopPadding;
		}
	}
}
