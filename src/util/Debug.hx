package util;

import haxe.CallStack.StackItem;

function callstack() {
	for ( i in haxe.CallStack.callStack() )
		switch i {
			case FilePos( s, file, line, column ):
				trace( 'FilePos($file:$line)' );
			default:
				trace( "not supported" );
		}
}

function traceStackItem( item : StackItem ) : String {
	return switch item {
		case FilePos( s, file, line, column ):
			'FilePos(${traceStackItem( s )}, $file:$line,)';
		case Method( classname, method ):
			'Method($classname, $method)';
		case LocalFunction( v ):
			'LocalFunction($v)';
		default: "";
	}
}
