package ui.core;

import dn.legacy.Color;
import hxd.Res;
import util.Assets;
import h3d.mat.Texture;
import hxd.Event;

class TextButton extends Button {

    public var prefix( default, set ) : String;

    function set_prefix( v : String ) {
        prefix = v;
        refresh( );
        return v;
    }

    var texDefault : Texture;
    var texPrefix : Texture;
    var texPrefixPressed : Texture;
    var colorDefault : Int;
    var colorPressed : Int;
    var title : String;

    public function new( title : String, prefix = "> ", ?action : Event -> Void, ?colorDefault : Int = 0xffffff, ?colorPressed : Int = 0x676767, ?parent ) {
        this.colorDefault = colorDefault;
        this.colorPressed = colorPressed;
        this.title = title;
        this.prefix = prefix;

        super(
            [h2d.Tile.fromTexture( texDefault ),
            h2d.Tile.fromTexture( texPrefix ),
            h2d.Tile.fromTexture( texPrefixPressed )],
            parent
        );
        onClickEvent.add( action != null ? action : ( _ ) -> {} );
        onClickEvent.add( ( e ) -> Res.sfx.click.play( 0.25 ) );
    }

    function refresh( ) {
        var text = new ShadowedText( Assets.fontPixel );
        text.color = Color.intToVector( colorDefault );

        text.text = prefix + title;
        texPrefix = new Texture( Std.int( text.textWidth ), Std.int( text.textHeight ), [Target] );
        text.drawTo( texPrefix );

        text.text = [for ( i in 0...prefix.length ) " "].join( "" ) + title;
        texDefault = new Texture( Std.int( texPrefix.width ), Std.int( texPrefix.height ), [Target] );
        text.drawTo( texDefault );

        text.color = Color.intToVector( colorPressed );
        texPrefixPressed = new Texture( Std.int( texPrefix.width ), Std.int( texPrefix.height ), [Target] );
        text.drawTo( texPrefixPressed );

        states = [h2d.Tile.fromTexture( texDefault ), h2d.Tile.fromTexture( texPrefix ), h2d.Tile.fromTexture( texPrefixPressed )];
        processStates( states );

        width = states[0].width;
        height = states[0].height;
    }
}
