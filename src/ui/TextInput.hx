package ui;

import hxd.Event;
import hxd.Key in K;

class TextInput extends h2d.TextInput {
	override function handleKey(e : Event) {
		switch( e.keyCode ) {
			case K.BACKSPACE if ( K.isDown(K.CTRL) ):
				if ( cursorIndex > 0 ) {
					var charset = hxd.Charset.getDefault();
					while( cursorIndex > 0 && !charset.isSpace(StringTools.fastCodeAt(text, cursorIndex - 1)) ) {
						beforeChange();
						cutSelection();
						onChange();
						cursorIndex--;
						text = text.substr(0, cursorIndex) + text.substr(cursorIndex + 1);
					}
				}
		}
		super.handleKey(e);
	}
}
