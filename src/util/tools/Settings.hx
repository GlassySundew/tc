package util.tools;

import Sys.SysError;
import h3d.Vector;
import haxe.io.Path;
import hxd.File;

@:publicFields
@:expose
@:keep
class Settings {

	static var SAVEPATH : String;

	static final appname = "Total_Condemn";

	public static var params : {
		nickname : String,
		fullscreen : Bool,
		inventoryVisible : Bool,
		playerCraftingVisible : Bool,
		inventoryCoordRatio : Vector,
		chestCoordRatio : Vector,
		playerCrafting : Vector,
		saveFiles : Array<String>
	} = {
		nickname : "unnamed player",
		fullscreen : false,
		inventoryCoordRatio : new Vector( -1, -1 ),
		inventoryVisible : false,
		chestCoordRatio : new Vector( -1, -1 ),
		playerCrafting : new Vector( -1, -1 ),
		playerCraftingVisible : false,
		saveFiles : [],
	};

	static var settingsPath : String;

	public static function init() {
		SAVEPATH = getSavePath();
		settingsPath = SAVEPATH + "settings";
	}

	static function getSavePath() {
		var path = switch Env.system {
			case Windows:
				Sys.getEnv( "AppData" ) + "/Roaming/" + appname;
			case Mac:
				Sys.getEnv( "HOME" ) + "/Library/Application Support/" + appname;
			case Linux:
				if ( Sys.getEnv( "XDG_CONFIG_HOME" ) != null ) {
					Sys.getEnv( "XDG_CONFIG_HOME" ) + "/" + appname;
				} else if ( Sys.getEnv( "HOME" ) != null ) {
					Sys.getEnv( "HOME" ) + "/.config/" + appname;
				} else throw "can not find suitable place for settings path";
			case _:
				throw "Unknown operating system.";
		}
		return haxe.io.Path.normalize( path ) + "/";
	}

	public static function saveSettings() {
		#if hl
		sys.FileSystem.createDirectory( Path.directory( settingsPath ) );
		#end

		hxd.Save.save( params, settingsPath );
	}

	public static function loadSettings() {
		#if hl
		sys.FileSystem.createDirectory( Path.directory( settingsPath ) );
		#end

		var data = hxd.Save.load( params, settingsPath );
		if ( data != null ) {
			params = data;
		} else
			sys.FileSystem.createDirectory( Path.directory( settingsPath ) );
		refreshSaves();
	}

	public static function refreshSaves() {
		var fileList : Array<String> = [];
		try {
			fileList = File.listDirectory( Save.saveDirectory );
		} catch( e : SysError ) {}

		for ( i in params.saveFiles.copy() ) if ( !fileList.contains( i + Const.SAVEFILE_EXT ) ) params.saveFiles.remove( i );

		for ( i in fileList ) {
			var saveFile = i.split( "." )[0];

			if ( !StringTools.startsWith( i, "." ) && StringTools.endsWith( i, Const.SAVEFILE_EXT ) && !params.saveFiles.contains( saveFile ) ) {
				params.saveFiles.push( saveFile );
			}
		}
	}
}
