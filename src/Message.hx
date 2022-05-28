import format.tmx.Data.TmxMap;

enum Message {

	/** seed on client side can only be used to generate icons in navigation window **/
	WorldInfo( seed : String );
	ClientInit( uid : Int );
	MapLoad( name : String, map : TmxMap );

	#if debug
	GetServerStatus;
	ServerStatus( isHost : Bool );
	#end
}

