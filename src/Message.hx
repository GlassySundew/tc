import format.tmx.Data.TmxMap;

enum Message {

	/** seed on client side can only be used to generate icons in navigation window **/
	WorldInfo( seed : String );
	PlayerBoot( uid : Int, nickname : String );
	MapLoad( name : String, map : TmxMap );
	SaveSystemOrder( type : SaveSystemOrderType );

	#if debug
	GetServerStatus;
	ServerStatus( isHost : Bool );
	#end
}

enum SaveSystemOrderType {
	CreateNewSave( name : String );
	SaveGame( name : String );
	DeleteSave( name : String );
}
