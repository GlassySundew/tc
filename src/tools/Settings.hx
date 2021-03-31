package tools;

import hxd.File;
import h3d.Vector;
import haxe.io.Path;

@:publicFields
@:expose
@:keep
class Settings {
	static var SAVEPATH : String = // Path.join([
		// #if windows Sys.getEnv("APPDATA"), #elseif linux Sys.getEnv("HOME"),
		// #end
		// "/.config/TotalCondemn/settings"
		"save" + "/"
	// ])
	;
	public static var nickname : String;
	public static var fullscreen : Bool;
	public static var inventoryCoordRatio : Vector = new Vector(-1, -1);
	public static var chestCoordRatio : Vector = new Vector(-1, -1);
	public static var saveFiles : Array<String> = [];

	public static function saveSettings() {
		#if hl
		sys.FileSystem.createDirectory(Path.directory((SAVEPATH + "settings")));
		#end

		hxd.Save.save({
			nickname : nickname,
			fullscreen : fullscreen,
			inventoryCoordRatio : inventoryCoordRatio,
			chestCoordRatio : chestCoordRatio,
			saveFiles : saveFiles,
		}, SAVEPATH + "settings");
	}

	public static function loadSettings() {
		var data = hxd.Save.load(null, SAVEPATH + "settings");
		if ( data != null ) {
			nickname = data.nickname;
			fullscreen = data.fullscreen;
			inventoryCoordRatio = data.inventoryCoordRatio != null ? data.inventoryCoordRatio : inventoryCoordRatio;
			chestCoordRatio = data.chestCoordRatio != null ? data.chestCoordRatio : chestCoordRatio;
			saveFiles = saveFiles;
		} else
			sys.FileSystem.createDirectory(Path.directory((SAVEPATH + "settings")));
		refreshSaves();
	}

	public static function refreshSaves() {
		var fileList = File.listDirectory(SAVEPATH);
		for (i in saveFiles) if ( !fileList.contains(i + Const.SAVEFILE_EXT) ) saveFiles.remove(i);

		for (i in fileList) {
			var saveFile = i.split(".")[0];

			if ( !StringTools.startsWith(i, ".") && StringTools.endsWith(i, Const.SAVEFILE_EXT) && !saveFiles.contains(saveFile) ) {
				saveFiles.push(saveFile);
			}
		}
	}
}
