package tools;

import haxe.rtti.Meta;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

class Macros {

	macro public static function initFields() {
		inline function isSerialized( field : haxe.macro.Type.ClassField ) : Bool {
			return Lambda.find( field.meta.get(), m -> m.name == ":s" ) != null;
		}

		var exprs : Array<Expr> = [];

		var fields = Context.getLocalClass().get().fields.get();
		for ( field in fields ) {
			var fname = field.name;
			var owner = "owner";

		Context.typeof( macro $i{fname} );

			// if ( Std.isOfType( macro $i{fname}, String ) && isSerialized( field ) ) {
			// 	exprs.push( macro this.$fname.$owner = ${macro this} );
			// }
		}
		return macro $b{exprs};
	}
}
