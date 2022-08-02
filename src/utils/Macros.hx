package utils;

import haxe.rtti.Meta;
import haxe.macro.Context;
import haxe.macro.Expr;
import cherry.soup.EventSignal.*;

using Lambda;

class Macros {

	macro public static function buildServerMessagesSignals() : Array<Field> {
		var fields = Context.getBuildFields();
		function getConstructor() {
			for ( field in fields )
				if ( field.name == "new" ) {
					switch field.kind {
						case FFun( f ):
							switch f.expr.expr {
								case EBlock( b ): return b;
								default: throw "not supported";
							}
						default:
							throw "not supported";
					}
				}
			throw "no constructor";
		}

		var serverConstructor = getConstructor();
		var pos = Context.currentPos();

		var mesEnum = Context.getType( "net.Message" );
		fields = fields.concat(
			( macro class {
				var mesEventsMap = new Map<Int, cherry.soup.EventSignal<Dynamic>>();
			} ).fields
		);

		// generating onMessage event signals, filling type parameters from message arguments
		switch mesEnum {
			case TEnum( constr, params ):
				var enumType = constr.get();
				for ( constructor in enumType.constructs ) {
					var types = [];
					var eventTypeStr : String = switch constructor.type {
						case TEnum( t, params ):
							"cherry.soup.EventSignal.EventSignal1";
						case TFun( args, ret ):
							types = args;
							'cherry.soup.EventSignal.EventSignal' + ( args.length + 1 );
						default: throw "not supported";
					};
					// changing event signals' types of type parameters
					var eventType = Context.getType( eventTypeStr );
					switch eventType {
						case TInst( t, params ):
							params[0] = Context.getType( 'NetworkClient' );
							for ( i => type in types ) {
								params[i + 1] = switch type.t {
									case TInst( t, _ ):
										Context.getType( '$t' );
									case TAbstract( t, _ ):
										Context.getType( '$t' );
									default: throw "not supported";
								}
							}
						default: throw "not supported";
					}

					var eventComplexType = Context.toComplexType( eventType );

					var eventTypePath = switch eventComplexType {
						case TPath( p ): p;
						default: throw "not supported";
					};

					var eventName = "on" + constructor.name + "Message";
					fields.push( {
						name : eventName,
						doc : null,
						meta : [],
						access : [APublic],
						kind : FVar(
							macro : $eventComplexType, macro new $eventTypePath()
						),
						pos : pos
					} );

					serverConstructor.push(
						macro {
							mesEventsMap[$v{constructor.index}] = $i{eventName};
						}
					);
				}
			default:
		}

		fields.push( {
			name : "onMessage",
			access : [APrivate],
			pos : pos,
			kind : FFun( {
				args : [
					{ name : "client", type : macro : hxbit.NetworkHost.NetworkClient },
					{ name : "message", type : macro : net.Message }
				],
				expr : {
					expr : EBlock( [
						macro {
							var enumParams = Type.enumParameters( message );
							switch enumParams.length {
								case 0:
									cast( mesEventsMap[Type.enumIndex( message )], cherry.soup.EventSignal.EventSignal1<Dynamic> )
										.dispatch( client );
								case 1:
									cast( mesEventsMap[Type.enumIndex( message )], cherry.soup.EventSignal.EventSignal2<Dynamic, Dynamic> )
										.dispatch( client, enumParams[0] );
								case 2:
									cast( mesEventsMap[Type.enumIndex( message )], cherry.soup.EventSignal.EventSignal3<Dynamic, Dynamic, Dynamic> )
										.dispatch( client, enumParams[0], enumParams[1] );
								case 3:
									cast( mesEventsMap[Type.enumIndex( message )], cherry.soup.EventSignal.EventSignal4<Dynamic, Dynamic, Dynamic, Dynamic> )
										.dispatch( client, enumParams[0], enumParams[1], enumParams[2] );
								default:
									throw "not supported";
							}
						}
					] ),
					pos : pos
				}
			} )
		} );
		return fields;
	}
}
