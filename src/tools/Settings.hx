package tools;

import h3d.Vector;
import haxe.io.Path;

@:publicFields
@:expose
@:keep
class Settings {
	static var SAVEPATH : String = Path.join([
		#if windows Sys.getEnv("APPDATA"), #elseif linux Sys.getEnv("HOME"),
		#end
		"/.config/TotalCondemn/settings"
	]);

	public static var nickname : String;
	public static var fullscreen : Bool;
	public static var inventoryCoordRatio : Vector = new Vector(-1, -1);

	public static function saveSettings() {
		#if hl
		sys.FileSystem.createDirectory(Path.directory(SAVEPATH));
		#end
		hxd.Save.save({
			nickname : nickname,
			fullscreen : fullscreen,
			inventoryCoordRatio : inventoryCoordRatio
		}, SAVEPATH);
	}

	public static function loadSettings() {
		var data = hxd.Save.load(null, SAVEPATH);
		if ( data != null ) {
			nickname = data.nickname;
			fullscreen = data.fullscreen;
			inventoryCoordRatio = data.inventoryCoordRatio != null ? data.inventoryCoordRatio : inventoryCoordRatio;
		}
	}
}
