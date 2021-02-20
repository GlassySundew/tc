import h2d.Layers;
import Level.StructTile;

interface GameAble {
	public var structTiles : Array<StructTile>;
	public var camera : Camera;
	public var root : Layers;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function applyTmxObjOnEnt(?ent : Null<Entity>) : Void;
	public function showStrTiles() : Void;
	public function hideStrTiles() : Void;
}
