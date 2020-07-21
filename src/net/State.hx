package net;


import io.colyseus.serializer.schema.Schema;

class State extends Schema {
	@:type("map", Player)
	public var players: MapSchema<Player> = new MapSchema<Player>();

}
