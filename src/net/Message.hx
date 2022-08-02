package net;

import format.tmx.TmxMap;

enum Message {

	/** seed on client side can only be used to generate icons in navigation window **/
	WorldInfo( seed : String );
	ClientInit( uid : Int );
	MapLoad( name : String, map : TmxMap );
	Disconnect;

	#if debug
	GetServerStatus;
	ServerStatus( isHost : Bool );
	#end
}
