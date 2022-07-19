package en.structures;

import en.player.Player;
import format.tmx.Data.TmxObject;
import hxbit.Serializer;
import hxd.Event;
import hxd.Key;
import net.ServerRPC;

class Door extends Structure {

	@:s public var leadsTo : String = "";

	public override function init( ?x : Float, ?z : Float, ?tmxObj : TmxObject ) {
		super.init( x, z, tmxObj );
		if ( tmxObj != null && tmxObj.properties.exists( "to" ) )
			leadsTo = tmxObj.properties.getString( "to" );
	}

	override function alive() @:privateAccess {
		super.alive();
		interactable = true;

		interact.onTextInputEvent.add( onTextInput );
	}

	function onTextInput( e : Event ) {
		if ( Key.isPressed( Key.E ) ) {
			turnOffHighlight();

			if ( leadsTo != null ) {
				var curLvl = GameClient.inst.sLevel.lvlName;

				// GameClient.inst.startLevel(leadsTo, {});
				loadLevel( Player.inst, leadsTo, ( e ) -> {} );

				GameClient.inst.onLevelChanged.add(
					() -> {
						var door = findDoor( curLvl );
						if ( door != null ) {
							interactable = true;
							trace( "moving player " );

							Player.inst.setFeetPos( door.footX, door.footY );
							GameClient.inst.targetCameraOnPlayer();
						}
					},
					true
				);
			}
		}
	}

	override function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		// return
		// 	switch( propId ) {
		// 		case _ => loadLevelId: true;
		// 		default: false;
		// 	}
		return true;
	}

	@:rpc( server )
	function loadLevel( player : Player, level : String ) : ServerLevel {
		return ServerRPC.bringPlayerToLevel( player, level );
	}

	function findDoor( to : String ) : Entity {
		for ( e in Entity.ALL ) {
			if ( e.isOfType( en.structures.Door ) ) {
				if ( e.tmxObj != null && e.tmxObj.properties.exists( "to" ) && e.tmxObj.properties.getFile( "to" ).split( "." )[0] == to ) {
					return e;
				}
			}
		}
		#if debug
		trace( "wrong door logic???" );
		#end
		return null;
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
