class Const {
	public static var FPS = 60;
	public static var AUTO_SCALE_TARGET_WID = -1; // -1 to disable auto-scaling on width
	public static var AUTO_SCALE_TARGET_HEI = -1; // -1 to disable auto-scaling on height
	public static var CAM_OFFSET = 240;
	public static var SCALE = 2.0; // ignored if auto-scaling
	public static var UI_SCALE = 2.0;
	public static var GRID_WIDTH = 48;
	public static var GRID_HEIGHT = 24;

	public static var MELEE_REACH = 2;
	public static var GRAB_REACH = 2;
	public static var DEF_USE_RANGE = 40.;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get, never):Int;

	static inline function get_NEXT_UNIQ()
		return _uniq++;

	public static var INFINITE = 1. / 0.;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_FX_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_TOP = _inc++;
	public static var DP_FX_TOP = _inc++;
	public static var DP_UI = _inc++;
	public static var DP_MASK = _inc++;
	public static var LEVELS_PATH = "tiled/levels/";
	public static var ATLAS_PATH = "tiled/atlas/";
}
