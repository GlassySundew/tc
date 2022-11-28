package ui.domkit.element;

import dn.heaps.slib.HSprite;
import ui.core.Button;
import util.Assets;

@:uiComp( "button" )
class ButtonComp extends Button implements h2d.domkit.Object {

	public function new( key : String, keyAmount : Int, ?callback : Void -> Void, ?parent : h2d.Object ) {
		var tiles = [for ( i in 0...keyAmount ) {
			new HSprite( Assets.ui, key + i ).tile;
		}];

		super( tiles, parent );

		onClickEvent.add(
			( e ) -> {
				callback();
			}
		);

		initComponent();
	}
}
