package util;

class Const {

	public static var FPS = 60;
	public static var AUTO_SCALE_TARGET_WID = -1; // -1 to disable auto-scaling on width
	public static var AUTO_SCALE_TARGET_HEI = -1; // -1 to disable auto-scaling on height
	public static var SCALE = 3; // ignored if auto-scaling
	public static var UI_SCALE = 2.0;
	public static var GRID_WIDTH = 48;
	public static var GRID_HEIGHT = 24;

	public static var MELEE_REACH = 2;
	public static var GRAB_REACH = 2;
	public static var DEF_USE_RANGE = 40.;

	static var _uniq = 0;
	public static var NEXT_UNIQ( get, never ) : Int;

	static inline function get_NEXT_UNIQ() return _uniq++;

	static var inc = 0;

	public static var DP_BG = inc++;
	public static var DP_FX_BG = inc++;
	public static var DP_MAIN = inc++;
	public static var DP_TOP = inc++;
	public static var DP_FX_TOP = inc++;

	public static var DP_UI_NICKNAMES = inc++;
	public static var DP_UI = inc++;
	public static var DP_UI_FRONT = inc++;
	public static var DP_MASK = inc++;
	public static var DP_IMGUI = inc++;

	
	public static var LEVELS_PATH = "tiled/levels/";
	public static var ATLAS_PATH = "tiled/atlas/";
	public static var SAVEFILE_EXT = ".zhopa";

	public static var jumpReach = 80;
}
