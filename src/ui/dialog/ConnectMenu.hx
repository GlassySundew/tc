package ui.dialog;

import h2d.RenderContext;
import hxd.Res;
import h2d.domkit.Style;
import h2d.Flow;
import h2d.Object;

class ConnectComp extends Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC = 
		<connect-comp layout="vertical" vspacing="5" >
			<shadowed-text( "Connect" ) scale="1.5" />

			<flow layout="horizontal" hspacing="5" valign="middle" content-valign="middle" >
				<shadowed-text( "ip: " ) valign="middle" />
				<text-input background-color-prop={0x80808080} input-width-prop="100" />
				<button-flow label="local" public id="localConnect" />
			</flow>
			
			<flow layout="horizontal" hspacing="5">
				<text-button( "connect" ) public id="connect" />
				<text-button( "cancel", "> ", (e)->{}, ${0x666666}, ${0x303030} ) public id="cancel" />
			</flow>
		</connect-comp>
	
	// @formatter:on
		var style : Style;

	public function new( ?parent ) {
		super( parent );
		initComponent();

		#if !debug
		localConnect.visible = false;
		#end

		style = new Style();
		style.load( Res.domkit.connectMenu );
		style.addObject( this );
	}

	override function sync( ctx : RenderContext ) {
		super.sync( ctx );
		style.sync();
	}
}

class ConnectMenu extends FocusMenu {

	public var textInput : TextInput;

	public function new( ?parent : Object, ?onGameStart : Void -> Void ) {
		super( parent );
		centrizeContent();

		function onConnect() {
			Main.inst.startGame( true );
			destroy();
		}

		var connectComp = new ConnectComp( contentFlow );
		connectComp.localConnect.onClick = () -> {
			MainMenu.hide();

			Main.inst.onClientControllerSetEvent.add(
				() -> Main.inst.clientController.spawnPlayer( Settings.params.nickname ),
				true
			);

			Client.inst.addOnConnectionCallback( onConnect );
			Client.inst.connect(() -> {
				Client.inst.onConnection.remove( onConnect );
			} );
		};

		connectComp.cancel.onClick = ( e ) -> {
			destroy();
		};
	}
}
