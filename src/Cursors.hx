import hxd.Cursor.CustomCursor;
import hxd.Pixels;
import h3d.mat.Texture;
import hxd.BitmapData;

class Cursors {
	public static var cursorScale = 2;

	public static function init() {
		function uploadPixels(pixels:Pixels, bmp:BitmapData) {
			for (i in 0...pixels.height)
				for (j in 0...pixels.width)
					bmp.setPixel(j, i, pixels.getPixel(j, i));
			return bmp;
		}

		var bmpMap = new Map<hxd.Cursor, Array<BitmapData>>();
		var cursors = [];

		// Default
		var sprCursor = Assets.ui.getBitmap("cursor");
		sprCursor.scale(cursorScale);
		var tex = new Texture(Std.int(sprCursor.tile.width * cursorScale), Std.int(sprCursor.tile.height * cursorScale), [Target]);
		sprCursor.drawTo(tex);
		var pixels = tex.capturePixels();
		cursors.push(uploadPixels(pixels, new BitmapData(Std.int(sprCursor.tile.width * cursorScale), Std.int(sprCursor.tile.height * cursorScale))));

		bmpMap.set(Default, cursors.copy());
		cursors = [];

		// Hand
		var sprCursorq = Assets.ui.getBitmap("cursor", 2, 0, 0);
		sprCursorq.scale(cursorScale);
		var tex = new Texture(Std.int(sprCursorq.tile.width * cursorScale), Std.int(sprCursorq.tile.height * cursorScale), [Target]);
		sprCursorq.drawTo(tex);
		var pixels = tex.capturePixels();
		cursors.push(uploadPixels(pixels, new BitmapData(Std.int(sprCursorq.tile.width * cursorScale), Std.int(sprCursorq.tile.height * cursorScale))));

		bmpMap.set(Button, cursors.copy());
		cursors = [];

		var defalutCur = new CustomCursor(bmpMap.get(Default), 0, 0, 0);
		var handCur = new CustomCursor(bmpMap.get(Button), 0, 6, 2);
		hxd.System.setCursor = function(cur:hxd.Cursor) {
			if (cur == Default) {
				// // Pressed (idk how to set)
				// var sprCursor = Assets.ui.getBitmap("cursor", 1);
				// sprCursor.scale(cursorScale);
				// var tex = new Texture(Std.int(sprCursor.tile.width * cursorScale), Std.int(sprCursor.tile.height * cursorScale), [Target]);
				// sprCursor.drawTo(tex);
				// var pixels = tex.capturePixels();
				// cursors.push(uploadPixels(pixels, new BitmapData(Std.int(sprCursor.tile.width * cursorScale), Std.int(sprCursor.tile.height * cursorScale))));
				hxd.System.setNativeCursor(Custom(defalutCur));
			} else if (cur == Button) {
				hxd.System.setNativeCursor(Custom(handCur));
			} else if (cur == Hide) {} else {
				hxd.System.setNativeCursor(cur);
			}
		}
	}
}
