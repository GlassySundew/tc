package tools;

import Sys.SysError;
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
	public static var params = {
		nickname : "unnamed player",
		fullscreen : false,
		inventoryCoordRatio : new Vector(-1, -1),
		inventoryVisible : false,
		chestCoordRatio : new Vector(-1, -1),
        playerCrafting : new Vector(-1, -1),
        playerCraftingVisible : false,
		saveFiles : [],
	};

	public static function saveSettings() {
		#if hl
		sys.FileSystem.createDirectory(Path.directory((SAVEPATH + "settings")));
		#end

		hxd.Save.save(params, SAVEPATH + "settings");
	}

	public static function loadSettings() {
		#if hl
		sys.FileSystem.createDirectory(Path.directory((SAVEPATH + "settings")));
		#end

		var data = hxd.Save.load(params, SAVEPATH + "settings");
		if ( data != null ) {
			params = data;
		} else
			sys.FileSystem.createDirectory(Path.directory((SAVEPATH + "settings")));
		refreshSaves();
	}

	public static function refreshSaves() {
		var fileList : Array<String> = [];
		try {
			fileList = File.listDirectory(SAVEPATH);
		} catch( e:SysError ) {}
		
		for (i in params.saveFiles.copy()) if ( !fileList.contains(i + Const.SAVEFILE_EXT) ) params.saveFiles.remove(i);

		for (i in fileList) {
			var saveFile = i.split(".")[0];

			if ( !StringTools.startsWith(i, ".") && StringTools.endsWith(i, Const.SAVEFILE_EXT) && !params.saveFiles.contains(saveFile) ) {
				params.saveFiles.push(saveFile);
			}
		}
	}
}
