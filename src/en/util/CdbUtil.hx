package en.util;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class CdbUtil {

	public static macro function getEntry(
		ent : ExprOf<Data.Entity>,
		fromAccess : ExprOf<String>,
		inTable : Expr
	) {
		var from = switch fromAccess.expr {
			case EConst( ident ):
				switch ident {
					case CString( string, _ ):
						string;
					default: "not supposed";
				}
			default: throw "not supposed";
		};

		return macro {
			{
				var result = null;
				for ( i in ${inTable} ) if ( i.$from.id == ${ent} ) result = i;
				result;
			}
		};
	}
}
