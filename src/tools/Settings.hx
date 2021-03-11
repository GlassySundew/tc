package tools;

import hxd.File;
import h3d.Vector;
import haxe.io.Path;

@:publicFields
@:expose
@:keep
class Settings {
	static var SAVEPATH : String = Path.join([
		// #if windows Sys.getEnv("APPDATA"), #elseif linux Sys.getEnv("HOME"),
		// #end
		// "/.config/TotalCondemn/settings"
		"save/settings"
	]);

	public static var nickname : String;
	public static var fullscreen : Bool;
	public static var inventoryCoordRatio : Vector = new Vector(-1, -1);
	public static var chestCoordRatio : Vector = new Vector(-1, -1);
	public static var saveFiles : Array<String> = [];

	public static function saveSettings() {
		#if hl
		sys.FileSystem.createDirectory(Path.directory(SAVEPATH));
		#end

		hxd.Save.save({
			nickname : nickname,
			fullscreen : fullscreen,
			inventoryCoordRatio : inventoryCoordRatio,
			chestCoordRatio : chestCoordRatio,
			saveFiles : saveFiles,
		}, SAVEPATH);
	}

	public static function loadSettings() {
		var data = hxd.Save.load(null, SAVEPATH);
		if ( data != null ) {
			nickname = data.nickname;
			fullscreen = data.fullscreen;
			inventoryCoordRatio = data.inventoryCoordRatio != null ? data.inventoryCoordRatio : inventoryCoordRatio;
			chestCoordRatio = data.chestCoordRatio != null ? data.chestCoordRatio : chestCoordRatio;
			saveFiles = saveFiles;
		}

		if ( saveFiles.length == 0 ) {
			var saveFiles = File.listDirectory("save");
			for (i in saveFiles) {
				if ( StringTools.endsWith(i, ".zhopa") ) {
					saveFiles.push(i.split(".")[0]);
				}
			}
		}
	}
}
