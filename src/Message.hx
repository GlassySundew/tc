import format.tmx.Data.TmxMap;

enum abstract MessageType( String ) from String to String {

	var playerInit = "playerInit";

	var mapLoad = "mapLoad";
}

@:structInit
class Message {
	@:optional public var type : MessageType;

	public function new( type : MessageType ) {
		this.type = type;
	}
}

@:structInit class PlayerInit extends Message {
	public var uid : Int;
	public var nickname : String;

	public function new( uid : Int, nickname : String ) {
		super(playerInit);
		this.uid = uid;
		this.nickname = nickname;
	}
}

@:structInit class MapLoad extends Message {
	public var name : String;
	public var map : TmxMap;

	public function new( name : String, map : TmxMap ) {
		super(mapLoad);
		this.name = name;
		this.map = map;
	}
}
