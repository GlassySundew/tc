package game.server.generation;

@:keepSub
abstract class ChunkGenerator {

	public var level : ServerLevel;

	abstract public function generateChunk( x : Int, y : Int ) : Void;

	abstract public function placeSnippet( x : Int, y : Int, mapName : String ) : Void;
}
