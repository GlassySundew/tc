import Level.StructTile;

interface GameAble {
	public var structTiles : Array<StructTile>;
	public function applyTmxObjOnEnt(?ent : Null<Entity>) : Void;
}
