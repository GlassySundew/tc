#if macro
import haxe.macro.Expr;
import haxe.io.Path;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Compiler;
#end

class Helper {
	#if macro
	// Initialize macro part.
	public static function init() {
		hxd.res.Config.extensions.set("json", "res.GpuPartsJson");
	}
	#end
}
