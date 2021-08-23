import h2d.Layers;
import Level.StructTile;

interface IGame {
	#if !headless
	public var structTiles : Array<StructTile>;
	public var camera : Camera;
	public var root : Layers;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function showStrTiles() : Void;
	public function hideStrTiles() : Void;
	#end
	public var network(get, never) : Bool;

	public function applyTmxObjOnEnt(?ent : Null<Entity>) : Void;
}
