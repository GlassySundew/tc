import hxd.Cursor;
import h3d.pass.Default;
import hxd.System;
import h2d.Object;
import h2d.Bitmap;
import h2d.Drawable;
import hxd.File;
import hxd.Cursor.CustomCursor;
import hxd.Pixels;
import h3d.mat.Texture;
import hxd.BitmapData;

class Cursors {
	public static var cursorScale = 2;
	static var currentCursor : Cursor = Default;

	static var objectPool : Array<Object> = [];

	public static function init() {
		refreshCursors();
	}

	static function refreshCursors() {

		function uploadPixels( pixels : Pixels, bmp : BitmapData ) {
			for ( i in 0...pixels.height ) for ( j in 0...pixels.width ) bmp.setPixel(j, i, pixels.getPixel(j, i));
			return bmp;
		}

		function getCursor( bmp : Bitmap ) {
			var cursors = [];
			bmp.scaleX = bmp.scaleY = (cursorScale);
			for ( i in objectPool ) {
				bmp.addChildAt(i, 0);
			}
			@:privateAccess bmp.sync(Boot.inst.s2d.ctx);
			var tex = new Texture(Std.int(bmp.getBounds().width * cursorScale), Std.int(bmp.getBounds().height * cursorScale), [Target]);
			bmp.drawTo(tex);
			var pixels = tex.capturePixels();

			cursors.push(uploadPixels(pixels, new BitmapData(Std.int(bmp.getBounds().width * cursorScale), Std.int(bmp.getBounds().height * cursorScale))));
			return cursors.copy();
		}
		
		/** BitmapDatas are for animation frames **/
		var bmpMap = new Map<hxd.Cursor, Array<BitmapData>>();
		bmpMap.set(Default, getCursor(Assets.ui.getBitmap("cursor")));
		bmpMap.set(Button, getCursor(Assets.ui.getBitmap("cursor", 1)));

		var defalutCur = new CustomCursor(bmpMap.get(Default), 0, 0, 0);
		var handCur = new CustomCursor(bmpMap.get(Button), 0, 0, 0);

		hxd.System.setCursor = function ( cur : hxd.Cursor ) {
			switch( cur ) {
				case Default:
					hxd.System.setNativeCursor(Custom(defalutCur));
					currentCursor = Cursor.Default;
				case Button:
					hxd.System.setNativeCursor(Custom(handCur));
					currentCursor = Cursor.Button;
				case Hide:
					currentCursor = Cursor.Hide;
				case Callback(f):
					f();
				default:
					hxd.System.setNativeCursor(cur);
			}
		}
		System.setCursor(currentCursor);
	}

	public static function passObjectForCursor( object : Object ) {
		if ( !objectPool.contains(object) ) objectPool.push(object);
		refreshCursors();
	}

	public static function removeObjectFromCursor( object : Object ) {
		objectPool.remove(object);
		refreshCursors();
	}
}
