package game.server;

import game.server.level.Chunks;
import en.util.EntityUtil.EntityTmxData;
import format.tmx.Data.TmxProperties;
import game.server.level.LevelController;
import game.server.generation.ChunkGenerator;
import util.Util;
import dn.Process;
import en.Entity;
import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxObject;
import format.tmx.TmxMap;
import format.tmx.Tools;
import hxbit.NetworkSerializable;
import net.NSArray;
import util.EregUtil;

using util.Extensions.TmxPropertiesExtension;

/**
	server-side level model
**/
class ServerLevel implements NetworkSerializable {

	@:s public var entities : NSArray<Entity> = new NSArray();
	@:s public var lvlName : String;

	public var chunks : Chunks;
	public var entitiesTmxObj : Array<TmxObject> = [];
	public var player : EntityTmxData = {};
	public var cdb : Data.World;
	public var sqlId : Null<Int>;
	public var generator : ChunkGenerator;
	public var properties : TmxProperties = new TmxProperties();
	public var ctrl : LevelController;

	public function new() {
		enableAutoReplication = true;

		ctrl = new LevelController( this );
		chunks = new Chunks( this );
	}

	public function networkAllow(
		op : hxbit.NetworkSerializable.Operation,
		propId : Int,
		clientSer : hxbit.NetworkSerializable
	) : Bool {
		var entitiesId : Int = networkPropEntities.toInt();
		return
			switch( propId ) {
				case _ => entitiesId: true;
				default: false;
			}
	}

	// TODO destroy itself if has no player instances for 5 seconds
	function gc() {
		for ( e in entities ) {}
	}
}
