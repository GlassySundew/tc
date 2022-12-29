package game.server.generation;

interface IChunkGenerator {
    function generateChunk(x : Int, y : Int) : Void;
}