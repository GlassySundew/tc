package ui;

import h3d.mat.Texture;
import hxd.Event;


class TextButton extends ui.Button {
	public function new( string : String, ?action : Event -> Void, ?colorDef : Int = 0xffffff, ?colorPressed : Int = 0x676767, ?parent ) {
		var text = new ShadowedText( Assets.fontPixel );
		text.color = Color.intToVector( colorDef );
		text.text = "  " + string;

		var tex0 = new Texture( Std.int( text.textWidth ), Std.int( text.textHeight ), [Target] );
		text.drawTo( tex0 );

		var tex1 = new Texture( Std.int( text.textWidth ), Std.int( text.textHeight ), [Target] );
		text.text = "> " + string;
		text.drawTo( tex1 );

		text.color = Color.intToVector( colorPressed );

		var tex2 = new Texture( Std.int( text.textWidth ), Std.int( text.textHeight ), [Target] );
		text.drawTo( tex2 );
		super( [h2d.Tile.fromTexture( tex0 ), h2d.Tile.fromTexture( tex1 ), h2d.Tile.fromTexture( tex2 )], parent );
		onClickEvent.add( action != null ? action : ( _ ) -> {} );
	}
}